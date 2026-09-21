package compiler

import "core:fmt"
import "core:strings"

Basic_Token_Type :: enum {
    NONE,
    ALPHANUMERIC,
    SYMBOLIC,
    SPECIAL_CHAR,
    STRING_LIT,
    COMMENT,
}

Basic_Token :: struct {
    type: Basic_Token_Type,
    text: string,
    line: int,
}

Lexer :: struct {
    str: string,
    done_i: int,
    curr_i: int,
    done_line: int,
    curr_line: int,
}

File_Position :: struct {
    line: int,
    char: int,
}

basic_tokenize :: proc(script: ^string) -> [dynamic]Basic_Token {
    lexer := Lexer{
        str = script^, 
        done_i = 0, 
        curr_i = 0, 
        done_line = 1,
        curr_line = 1,
    }
    
    tokens := make([dynamic]Basic_Token)

    loop: for true {
        token_type := find_next_token(&lexer)

        new_token: Basic_Token

        switch token_type {
        case .NONE:         break loop
        case .ALPHANUMERIC: new_token = process_alphanum(&lexer)
        case .SYMBOLIC:     new_token = process_symbolic(&lexer)
        case .SPECIAL_CHAR: new_token = process_special_char(&lexer)
        case .STRING_LIT:   new_token = process_string(&lexer)
        case .COMMENT:      new_token = process_comment(&lexer)
        }

        append(&tokens, new_token)

        lexer_confirm(&lexer)
    }

    return tokens
}

lexer_has_char :: proc(lexer: ^Lexer) -> bool {
    return len(lexer.str) > lexer.curr_i
}
lexer_advance :: proc(lexer: ^Lexer) -> u8 {
    c := lexer.str[lexer.curr_i]

    lexer.curr_i += 1
    if c == '\n' do lexer.curr_line += 1

    return c
}
lexer_peek :: proc(lexer: ^Lexer) -> u8 {
    return lexer.str[lexer.curr_i]
}
lexer_backtrack :: proc(lexer: ^Lexer) {
    lexer.curr_i -= 1

    c := lexer.str[lexer.curr_i]
    if c == '\n' do lexer.curr_line -= 1
}
lexer_confirm :: proc(lexer: ^Lexer) {
    lexer.done_i = lexer.curr_i
    lexer.done_line = lexer.curr_line
}
lexer_substring :: proc(lexer: ^Lexer) -> string {
    return lexer.str[lexer.done_i : lexer.curr_i]
}

find_next_token :: proc(lexer: ^Lexer) -> Basic_Token_Type {
    for lexer_has_char(lexer) {
        
        c := lexer_advance(lexer)

        if is_alphanumeric(c) {
            return .ALPHANUMERIC
        }
        else if in_char_set(symbolic_chars, c) {
            return .SYMBOLIC
        }
        else if in_char_set(reserved_chars, c) {
            return .SPECIAL_CHAR
        }
        else if c == '"' {
            return .STRING_LIT
        }

        lexer_confirm(lexer)
    }

    return .NONE
}

process_alphanum :: proc(lexer: ^Lexer) -> Basic_Token {
    for lexer_has_char(lexer) {
        
        c := lexer_advance(lexer)
        
        if !is_alphanumeric(c) do break
    }

    lexer_backtrack(lexer)

    return Basic_Token{
        type = .ALPHANUMERIC, 
        text = strings.clone(lexer_substring(lexer)), 
        line = lexer.done_line
    }
}

process_special_char :: proc(lexer: ^Lexer) -> Basic_Token {
    // check for comment
    if lexer.str[lexer.curr_i - 1] == '(' {
        if lexer_has_char(lexer) {
            if lexer_advance(lexer) == '*' {
                return process_comment(lexer)
            }
            lexer_backtrack(lexer)
        }
    }

    // otherwise always is 1 character
    return Basic_Token{
        type = .SPECIAL_CHAR, 
        text = strings.clone(lexer_substring(lexer)), 
        line = lexer.done_line
    }
}

process_symbolic :: proc(lexer: ^Lexer) -> Basic_Token {

    for lexer_has_char(lexer) {
        
        c := lexer_advance(lexer)
        
        if !in_char_set(symbolic_chars, c) do break
    }

    lexer_backtrack(lexer)

    return Basic_Token{
        type = .SYMBOLIC, 
        text = strings.clone(lexer_substring(lexer)), 
        line = lexer.done_line
    }
}

process_comment :: proc(lexer: ^Lexer) -> Basic_Token {
    process_comment_rec(lexer)

    return Basic_Token{
        type = .COMMENT, 
        text = strings.clone(lexer_substring(lexer)), 
        line = lexer.done_line
    }
}

// this function expects to start just inside the comment and finishes just outside it
process_comment_rec :: proc(lexer: ^Lexer) {
    prev_c: u8 = ' '

    for lexer_has_char(lexer) {
        
        c := lexer_advance(lexer)
        
        if prev_c == '*' && c == ')' {
            return
        }
        if prev_c == '(' && c == '*' {
            process_comment_rec(lexer)
        }

        prev_c = c
    }

    fmt.printfln(`Missing end of comment starting at line %d`, lexer.done_line)
}

process_string :: proc(lexer: ^Lexer) -> Basic_Token {

    Escape_Status :: enum {
        NONE,
        BACKSLASH,
        WHITESPACE,
        CONTROL, 
        DIGIT,
    }
    
    escape_status := Escape_Status.NONE
    num_digits := 0

    loop: for lexer_has_char(lexer) {

        c := lexer_advance(lexer)

        switch escape_status {
        case .NONE: 
            if c == '"' do break loop
            if c == '\\' do escape_status = .BACKSLASH

        case .BACKSLASH:
            switch c {
            case 'n', 't', '"', '\\':
                escape_status = .NONE
            case '^':
                escape_status = .CONTROL
            case '0'..='9':
                escape_status = .DIGIT
                num_digits = 1
            case:
                if in_char_set(whitespace_chars, c) {
                    escape_status = .WHITESPACE
                }
                else {
                    fmt.printfln("unexpected character in escape sequence: '%c'", c)
                }
            }

        case .WHITESPACE:
            // format: "\   [newline]   \" or any other sequence of whitespace characters
            // value: ignored
            if !in_char_set(whitespace_chars, c) {
                if c != '\\' {
                    fmt.printfln("unexpected character in escape sequence: '%c'", c)
                }
                escape_status = .NONE
            }

        case .CONTROL:
            // format: "\^[char]" where [char] is a character between 64 and 95 inclusive
            // value: the control character with value (r - 64)
            if c < 64 || c > 95 {
                fmt.printfln("bad escape sequence: \\^%c", c)
            }
            escape_status = .NONE

        case .DIGIT:
            // format: "\[a][b][c]" where each of [a], [b], [c] is a digit. min 000, max 255
            // value: the character with value [a][b][c]
            if c >= '0' && c <= '9' {
                num_digits += 1

                if num_digits >= 3 {
                    escape_status = .NONE
                }
            }
            else {
                fmt.printfln("unexpected character in escape sequence: '%c'", c)
                escape_status = .NONE
            }
        }
    }

    return Basic_Token{
        type = .STRING_LIT, 
        text = strings.clone(lexer_substring(lexer)), 
        line = lexer.done_line
    }
}

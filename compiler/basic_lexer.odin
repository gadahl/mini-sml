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
    reader: strings.Reader,
    token_start: int,
    line: int
}

basic_tokenize :: proc(script: ^string) -> [dynamic]Basic_Token {
    reader: strings.Reader
    strings.reader_init(&reader, script^)
    lexer := Lexer{
        reader = reader, 
        token_start = 0, 
        line = 1, 
    }
    
    tokens := make([dynamic]Basic_Token)

    loop: for true {
        token_type, prev_pos := find_next_token(&lexer)
        lexer.token_start = prev_pos

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
    }

    return tokens
}

find_next_token :: proc(lexer: ^Lexer) -> (Basic_Token_Type, int) {
    prev_pos : int
    for true {
        prev_pos = int(lexer.reader.i)

        r, r_size, err := strings.reader_read_rune(&lexer.reader)
        if err == .EOF do return .NONE, prev_pos
        if err != nil do panic(fmt.tprintf("error: %v", err))

        if r == '\n' do lexer.line += 1

        if r == '(' {
            next_r, next_size, next_err := strings.reader_read_rune(&lexer.reader)
            if err != .EOF {
                if err != nil do panic(fmt.tprintf("error: %v", err))
                
                if next_r == '*' {
                    return .COMMENT, prev_pos
                }

                strings.reader_unread_rune(&lexer.reader)
            }
        }

        if is_alphanumeric(r) {
            return .ALPHANUMERIC, prev_pos
        }
        else if in_char_set(symbolic_chars, r) {
            return .SYMBOLIC, prev_pos
        }
        else if in_char_set(reserved_chars, r) {
            return .SPECIAL_CHAR, prev_pos
        }
        else if r == '"' {
            return .STRING_LIT, prev_pos
        }
    }

    return .NONE, prev_pos
}

process_alphanum :: proc(lexer: ^Lexer) -> Basic_Token {
    prev_pos : int
    for true {
        prev_pos = int(lexer.reader.i)
        r, r_size, err := strings.reader_read_rune(&lexer.reader)
        
        if err == .EOF do break
        if err != nil do panic(fmt.tprintf("error: %v", err))
        
        if r == '\n' do lexer.line += 1
        
        if !is_alphanumeric(r) do break
    }

    lexer.reader.i = i64(prev_pos)
    text := lexer.reader.s[lexer.token_start : prev_pos]
    return Basic_Token{.ALPHANUMERIC, strings.clone(text), lexer.line}
}

process_special_char :: proc(lexer: ^Lexer) -> Basic_Token {
    // always is 1 character
    text := lexer.reader.s[lexer.token_start : int(lexer.reader.i)]
    return Basic_Token{.SPECIAL_CHAR, strings.clone(text), lexer.line}
}

process_symbolic :: proc(lexer: ^Lexer) -> Basic_Token {
    prev_pos : int
    for true {
        prev_pos = int(lexer.reader.i)
        r, r_size, err := strings.reader_read_rune(&lexer.reader)
        
        if err == .EOF do break
        if err != nil do panic(fmt.tprintf("error: %v", err))
        
        if r == '\n' do lexer.line += 1

        if !in_char_set(symbolic_chars, r) do break
    }

    lexer.reader.i = i64(prev_pos)
    text := lexer.reader.s[lexer.token_start : prev_pos]
    return Basic_Token{.SYMBOLIC, strings.clone(text), lexer.line}
}

process_comment :: proc(lexer: ^Lexer) -> Basic_Token {
    process_comment_rec(lexer)

    text := lexer.reader.s[lexer.token_start : int(lexer.reader.i)]
    return Basic_Token{.COMMENT, strings.clone(text), lexer.line}
}

// this function expects to start just inside the comment and finishes just outside it
process_comment_rec :: proc(lexer: ^Lexer) {
    prev_r: rune = ' '

    for true {
        r, _, err := strings.reader_read_rune(&lexer.reader)
        
        if err == .EOF {
            fmt.printfln(`Missing end of comment "*)"`)
            return
        }
        if err != nil do panic(fmt.tprintf("error: %v", err))
        
        if r == '\n' do lexer.line += 1

        if prev_r == '*' && r == ')' {
            return
        }
        if prev_r == '(' && r == '*' {
            process_comment_rec(lexer)
        }

        prev_r = r
    }
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

    prev_pos: int
    loop: for true {
        prev_pos = int(lexer.reader.i)
        r, r_size, err := strings.reader_read_rune(&lexer.reader)
        
        if err == .EOF do break
        if err != nil do panic(fmt.tprintf("error: %v", err))
        
        if r == '\n' do lexer.line += 1

        switch escape_status {
        case .NONE: 
            if r == '"' do break loop
            if r == '\\' do escape_status = .BACKSLASH

        case .BACKSLASH:
            switch r {
            case 'n', 't', '"', '\\':
                escape_status = .NONE
            case '^':
                escape_status = .CONTROL
            case '0'..='9':
                escape_status = .DIGIT
                num_digits = 1
            case:
                if in_char_set(whitespace_chars, r) {
                    escape_status = .WHITESPACE
                }
                else {
                    fmt.printfln("unexpected character in escape sequence: '%r'", r)
                }
            }

        case .WHITESPACE:
            // format: "\   [newline]   \" or any other sequence of whitespace characters
            // value: ignored
            if !in_char_set(whitespace_chars, r) {
                if r != '\\' {
                    fmt.printfln("unexpected character in escape sequence: '%r'", r)
                }
                escape_status = .NONE
            }

        case .CONTROL:
            // format: "\^[char]" where [char] is a character between 64 and 95 inclusive
            // value: the control character with value (r - 64)
            if r < 64 || r > 95 {
                fmt.printfln("bad escape sequence: \\^%r", r)
            }
            escape_status = .NONE

        case .DIGIT:
            // format: "\[a][b][c]" where each of [a], [b], [c] is a digit. min 000, max 255
            // value: the character with value [a][b][c]
            if r >= '0' && r <= '9' {
                num_digits += 1

                if num_digits >= 3 {
                    escape_status = .NONE
                }
            }
            else {
                fmt.printfln("unexpected character in escape sequence: '%r'", r)
                escape_status = .NONE
            }
        }
    }

    text := lexer.reader.s[lexer.token_start : int(lexer.reader.i)]
    return Basic_Token{.STRING_LIT, strings.clone(text), lexer.line}
}
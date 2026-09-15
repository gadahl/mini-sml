package compiler

import "core:fmt"
import "core:strings"

Basic_Token_Type :: enum {
    NONE,
    ALPHANUMERIC,
    SYMBOLIC,
    SPECIAL_CHAR,
    STRING_LIT,
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

process_string :: proc(lexer: ^Lexer) -> Basic_Token {
    in_escape_sequence := false
    in_whitespace_escape := false
    in_control_escape := false
    in_digit_escape := false
    num_digits := 0

    prev_pos: int
    for true {
        prev_pos = int(lexer.reader.i)
        r, r_size, err := strings.reader_read_rune(&lexer.reader)
        
        if err == .EOF do break
        if err != nil do panic(fmt.tprintf("error: %v", err))
        
        if r == '\n' do lexer.line += 1

        if in_escape_sequence {
            if in_control_escape {
                if r < 64 || r > 95 {
                    fmt.printfln("bad escape sequence: \\^%r", r)
                }
                in_control_escape = false
                in_escape_sequence = false
            }
            else if in_digit_escape {
                if is_numeric(r) {
                    num_digits += 1
                }
                else {
                    fmt.printfln("unexpected character in escape sequence: '%r'", r)
                    in_digit_escape = false
                    in_escape_sequence = false
                }
                if num_digits >= 3 {
                    in_digit_escape = false
                    in_escape_sequence = false
                }
            }
            else if in_whitespace_escape {
                if !in_char_set(whitespace_chars, r) {
                    if r != '\\' {
                        fmt.printfln("unexpected character in escape sequence: '%r'", r)
                    }
                    in_whitespace_escape = false
                    in_escape_sequence = false
                }
            }
            else if r == 'n' || r == 't' || r == '"' || r == '\\' {
                in_escape_sequence = false
            }
            else if r == '^' {
                in_control_escape = true
            }
            else if is_numeric(r) {
                in_digit_escape = true
                num_digits = 1
            }
            else if in_char_set(whitespace_chars, r) {
                in_whitespace_escape = true
            }
            else {
                fmt.printfln("invalid escape sequence")
            }
        }
        else {
            if r == '"' do break
            if r == '\\' do in_escape_sequence = true
        }
    }

    text := lexer.reader.s[lexer.token_start : int(lexer.reader.i)]
    return Basic_Token{.STRING_LIT, strings.clone(text), lexer.line}
}
package compiler

import "core:fmt"
import "core:strings"
import str "core:strings"
import "core:math"


Literal_Value :: union {
    Undefined,
    No_Value,
    i32,
    f32,
    string,
}
Undefined :: struct {}
No_Value :: struct {}

Lexer :: struct {
    str: string,
    done_i: int,
    curr_i: int,
    done_line: int,
    curr_line: int,
}


Token_Type :: enum {
    RESERVED_KEYWORD,
    TYPE_VAR,
    ALPHANUM_IDENT,
    SYMBOLIC_IDENT,
    INTEGER_LIT,
    STRING_LIT,
    REAL_LIT,
    COMMENT,
    WILDCARD,
}

Token :: struct {
    type: Token_Type,
    text: string,
    literal_value: Literal_Value,
    line: int,
}


in_char_set :: proc(char_set: string, c: u8) -> bool {
    return strings.index_byte(char_set, c) >= 0
}

is_alpha :: proc(c: u8) -> bool {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '\''
}

is_numeric :: proc(c: u8) -> bool {
    return c >= '0' && c <= '9'
}

is_alphanumeric :: proc(c: u8) -> bool {
    return is_alpha(c) || is_numeric(c) || c == '_'
}


tokenize :: proc(script: ^string) -> [dynamic]Token {
    lexer := Lexer{
        str = script^, 
        done_i = 0, 
        curr_i = 0, 
        done_line = 1,
        curr_line = 1,
    }
    
    tokens := make([dynamic]Token)

    for lexer_has_char(&lexer) {

        consume_spaces(&lexer)

        if token, ok := process_next_token(&lexer).(Token); ok {
            append(&tokens, token)
            lexer_confirm(&lexer)
        }
        else {
            break
        }
    }

    return tokens
}

lexer_has_char :: proc(lexer: ^Lexer) -> bool {
    return lexer.curr_i < len(lexer.str)
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
lexer_token_slice :: proc(lexer: ^Lexer) -> string {
    return lexer.str[lexer.done_i : lexer.curr_i]
}

Lexer_State :: struct {i: int, line: int}
lexer_save :: proc(lexer: ^Lexer) -> Lexer_State {
    return {lexer.curr_i, lexer.curr_line}
}
lexer_load :: proc(state: Lexer_State, lexer: ^Lexer) {
    lexer.curr_i = state.i
    lexer.curr_line = state.line
}


process_next_token :: proc(lexer: ^Lexer) -> Maybe(Token) {
    if t, ok := process_alpha_ident(lexer).(Token); ok {
        return t
    }
    else if t, ok := process_num_token(lexer).(Token); ok {
        return t
    }
    else if t, ok := process_wildcard(lexer).(Token); ok {
        return t
    }
    else if t, ok := process_comment(lexer).(Token); ok {
        return t
    }
    else if t, ok := process_dots(lexer).(Token); ok {
        return t
    }
    else if t, ok := process_symbolic(lexer).(Token); ok {
        return t
    }
    else if t, ok := process_special_char(lexer).(Token); ok {
        return t
    }
    else if t, ok := process_string(lexer).(Token); ok {
        return t
    }
    else {
        return nil
    }
}

consume_spaces :: proc(lexer: ^Lexer) {

    for lexer_has_char(lexer) {
        
        c := lexer_advance(lexer)
        
        if !in_char_set(whitespace_chars, c) {
            lexer_backtrack(lexer)
            return
        }

        lexer_confirm(lexer)
    }
}

process_alpha_ident :: proc(lexer: ^Lexer) -> Maybe(Token) {

    if lexer_has_char(lexer) {

        c := lexer_advance(lexer)

        if !is_alpha(c) {
            lexer_backtrack(lexer)
            return nil
        }
    }

    for lexer_has_char(lexer) {

        c := lexer_advance(lexer)
        
        if !is_alphanumeric(c) {
            lexer_backtrack(lexer)
            break
        }
    }

    text := str.clone(lexer_token_slice(lexer))

    for keyword in alpha_keywords {
        if strings.compare(text, keyword) == 0 {
            return Token{
                type = .RESERVED_KEYWORD, 
                text = text, 
                literal_value = No_Value{}, 
                line = lexer.done_line
            }
        }
    }

    return Token{
        type = .ALPHANUM_IDENT,
        text = text,
        literal_value = No_Value{},
        line = lexer.done_line,
    }
}


process_char :: proc(target: u8, lexer: ^Lexer) -> Maybe(u8) {

    if !lexer_has_char(lexer) do return nil

    c := lexer_advance(lexer)
    if c != target {
        lexer_backtrack(lexer)
        return nil
    }
    return c
}

process_num_token :: proc(lexer: ^Lexer) -> Maybe(Token) {
    type: Token_Type
    literal := process_num(lexer)

    #partial switch _ in literal {

    case i32: 
        type = .INTEGER_LIT

    case f32: 
        type = .REAL_LIT

    case:
        return nil
    }

    return Token{
        type = type, 
        text = str.clone(lexer_token_slice(lexer)), 
        literal_value = literal,
        line = lexer.done_line,
    }
}

process_num :: proc(lexer: ^Lexer) -> Literal_Value {

    state := lexer_save(lexer)

    if decimal, ok := process_decimal(lexer).(f32); ok {

        if _, ok := process_char('E', lexer).(u8); ok {

            if exp, ok := process_int(lexer).(i32); ok {

                return decimal * math.pow10(f32(exp));
            }
            else {
                fmt.println("Malformed exponential notation")
            }
        }
        else {
            return decimal
        }
    }
    else if n, ok := process_int(lexer).(i32); ok {

        if _, ok := process_char('E', lexer).(u8); ok {

            if exp, ok := process_int(lexer).(i32); ok {

                return f32(n) * math.pow10(f32(exp));
            }
            else {
                fmt.println("Malformed exponential notation")
            }
        }
        else {
            return n
        }
    }

    lexer_load(state, lexer)
    return Undefined{}
}

// takes XXX and YYYY and gives XXX.YYYY
combine_to_float :: proc(whole: i32, fraction: Digits) -> f32 {
    result := f32(fraction.value)
    for i in 0..<fraction.length {
        result *= 0.1
    }
    return f32(whole) + result
}

// Gets XXX.YYYY (or ~XXX.YYYY or 0.YYYY or ~0.YYYY)
process_decimal :: proc(lexer: ^Lexer) -> Maybe(f32) {

    state := lexer_save(lexer)

    sign: f32 = 1
    if _, ok := process_char('~', lexer).(u8); ok {
        sign = -1
    }
    
    if whole, ok := process_unsigned_int(lexer).(i32); ok {

        if _, ok := process_char('.', lexer).(u8); ok {
            
            if frac, ok := process_digits(lexer).(Digits); ok {
                
                if frac.length > 0 {
                    return sign * combine_to_float(whole, frac)
                }
            }
        }
    }

    lexer_load(state, lexer)
    return nil
}

// gets ~XXX or XXX or ~0 or 0
process_int :: proc(lexer: ^Lexer) -> Maybe(i32) {
    state := lexer_save(lexer)

    sign: i32 = 1
    if _, ok := process_char('~', lexer).(u8); ok {
        sign = -1
    }
    
    if n, ok := process_unsigned_int(lexer).(i32); ok {
        return sign * n
    }

    lexer_load(state, lexer)
    return nil
}

Digits :: struct {
    value: i32,
    length: i32,
}
// gets YYYY (can start with 0)
process_digits :: proc(lexer: ^Lexer) -> Maybe(Digits) {

    result: i32 = 0
    count: i32 = 0
    for lexer_has_char(lexer) {
        c := lexer_advance(lexer)
        if c < '0' || c > '9' {
            lexer_backtrack(lexer)
            break
        }

        digit := i32(c - '0')
        result = result * 10 + digit
        count += 1
        // TODO: check for integer literals that are too big? (-2^31 <= n < 2^31)
    }

    return Digits{result, count}
}


// gets `0` or `[1-9][0-9]*`
process_unsigned_int :: proc(lexer: ^Lexer) -> Maybe(i32) {

    state := lexer_save(lexer)

    if _, ok := process_char('0', lexer).(u8); ok {
        c := lexer_peek(lexer)
        if !is_alphanumeric(c) do return 0
    }
    else if digits, ok := process_digits(lexer).(Digits); ok { 
        if digits.length > 0 {
            return digits.value
        }       
    }

    lexer_load(state, lexer)
    return nil
}

process_wildcard :: proc(lexer: ^Lexer) -> Maybe(Token) {

    if lexer_has_char(lexer) && lexer_peek(lexer) == '_' {

        lexer_advance(lexer)

        if lexer_has_char(lexer) && is_alphanumeric(lexer_peek(lexer)) {

            lexer_backtrack(lexer)
            return nil
        }

        return Token{
            type = .WILDCARD,
            text = str.clone(lexer_token_slice(lexer)),
            literal_value = No_Value{}, 
            line = lexer.done_line,
        }
        
    }

    return nil
}

process_dots :: proc(lexer: ^Lexer) -> Maybe(Token) {

    count := 0
    for lexer_has_char(lexer) {
        
        c := lexer_peek(lexer)
        
        if c == '.' {
            lexer_advance(lexer)
            count += 1
        }
        else do break
    }
    if count == 0 {
        return nil
    }
    else if count == 1 || count == 3 {
        return Token{
            type = .RESERVED_KEYWORD, 
            text = str.clone(lexer_token_slice(lexer)),
            literal_value = No_Value{}, 
            line = lexer.done_line,
        }
    }
    else {
        fmt.printfln("Error: cannot parse %d sequential '.' characters", count)
        return nil
    }
}

process_special_char :: proc(lexer: ^Lexer) -> Maybe(Token) {
    
    if lexer_has_char(lexer) {

        c := lexer_advance(lexer) 

        if in_char_set(reserved_chars, c) {
            
            return Token{
                type = .RESERVED_KEYWORD, 
                text = str.clone(lexer_token_slice(lexer)),
                literal_value = No_Value{}, 
                line = lexer.done_line,
            }
        } 

        lexer_backtrack(lexer)
    }

    return nil
}

process_symbolic :: proc(lexer: ^Lexer) -> Maybe(Token) {

    empty := true
    for lexer_has_char(lexer) {
        
        c := lexer_advance(lexer)
        
        if !in_char_set(symbolic_chars, c) {
            lexer_backtrack(lexer)
            break
        }
        empty = false
    }
    if empty do return nil

    text := str.clone(lexer_token_slice(lexer))

    for keyword in symbolic_keywords {
        if strings.compare(text, keyword) == 0 {
            return Token{
                type = .RESERVED_KEYWORD, 
                text = text, 
                literal_value = No_Value{}, 
                line = lexer.done_line
            }
        }
    }

    return Token{
        type = .SYMBOLIC_IDENT,
        text = text,
        literal_value = No_Value{},
        line = lexer.done_line,
    }
}

process_comment :: proc(lexer: ^Lexer) -> Maybe(Token) {

    if process_comment_rec(lexer) {
        return Token{
            type = .COMMENT, 
            text = str.clone(lexer_token_slice(lexer)), 
            literal_value = No_Value{},
            line = lexer.done_line,
        }
    }
    else {
        return nil
    }
}

process_comment_rec :: proc(lexer: ^Lexer) -> bool {

    state := lexer_save(lexer)

    if _, ok := process_char('(', lexer).(u8); ok {
        
        if _, ok := process_char('*', lexer).(u8); ok {
            
            for lexer_has_char(lexer) {

                state := lexer_save(lexer)
                if _, ok := process_char('*', lexer).(u8); ok {

                    if _, ok := process_char(')', lexer).(u8); ok {

                        return true
                    }
                }
                lexer_load(state, lexer)

                if process_comment_rec(lexer) {
                    continue
                }

                lexer_advance(lexer)
            }

            fmt.printfln(`Missing end of comment starting at line %d`, lexer.done_line)

            return true
        }
    }

    lexer_load(state, lexer)
    return false
}

process_string :: proc(lexer: ^Lexer) -> Maybe(Token) {

    if _, ok := process_char('"', lexer).(u8); ok {} else {
        return nil
    }

    Escape_Status :: enum {
        NONE,
        BACKSLASH,
        WHITESPACE,
        CONTROL, 
        DIGIT,
    }
    
    escape_status := Escape_Status.NONE
    num_digits := 0
    digit_value := 0

    builder := str.builder_make()

    loop: for lexer_has_char(lexer) {

        c := lexer_advance(lexer)

        switch escape_status {
        case .NONE: 
            if c == '"' {
                break loop
            }
            else if c == '\\' {
                escape_status = .BACKSLASH
            }
            else {
                str.write_byte(&builder, c)
            }

        case .BACKSLASH:
            switch c {
            case 'n':
                str.write_byte(&builder, '\n')
                escape_status = .NONE
            case 't':
                str.write_byte(&builder, '\t')
                escape_status = .NONE
            case '"': 
                str.write_byte(&builder, '"')
                escape_status = .NONE
            case '\\':
                str.write_byte(&builder, '\\')
                escape_status = .NONE
            case '^':
                escape_status = .CONTROL
            case '0'..='9':
                escape_status = .DIGIT
                num_digits = 1
                digit_value = int(c - '0')
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
            if c >= 64 && c <= 95 {
                str.write_byte(&builder, c - 64)
            } 
            else {
                fmt.printfln("bad escape sequence: \\^%c", c)
            }
            escape_status = .NONE

        case .DIGIT:
            // format: "\[a][b][c]" where each of [a], [b], [c] is a digit. min 000, max 255
            // value: the character with value [a][b][c]
            if c >= '0' && c <= '9' {
                num_digits += 1
                
                digit_value *= 10;
                digit_value += int(c - '0')

                if num_digits >= 3 {
                    if (digit_value <= 255) {
                        str.write_byte(&builder, u8(digit_value))
                    } 
                    else {
                        fmt.printfln("number too large (greater than 255) in escape sequence: \\%d", digit_value)
                    }

                    escape_status = .NONE
                }
            }
            else {
                fmt.printfln("unexpected character in escape sequence: '%c'", c)
                escape_status = .NONE
            }
        }
    }

    return Token{
        type = .STRING_LIT, 
        text = str.clone(lexer_token_slice(lexer)), 
        literal_value = str.to_string(builder),
        line = lexer.done_line,
    }
}

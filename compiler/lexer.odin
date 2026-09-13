package compiler

import "core:fmt"
import "core:strings"

Token_Type :: enum {
    ALPHANUMERIC,
    SYMBOLIC,
    SPECIAL_CHAR,
    NONE,
}

Token :: struct {
    type: Token_Type,
    text: string,
    line: int,
}

Lexer :: struct {
    reader: strings.Reader,
    token_start: int,
    type: Token_Type,
    line: int,
}

main :: proc() {
    script := "fun f' 0 _ b = b \n  | f' n a b = f' (n-1) (a+b) a; \n fun f n = f' n 1 0; \nf 10;"
    
    tokens := tokenize(&script)
    defer delete(tokens)

    for token in tokens {
        switch token.type {
        case .ALPHANUMERIC: 
            fmt.println("ALPHANUM", token.text)
        case .SYMBOLIC: 
            fmt.println("SYMBOLIC", token.text)
        case .SPECIAL_CHAR: 
            fmt.println("SPECIAL ", token.text)
        case .NONE: 
            fmt.println("NONE")
        }
    }
}

is_whitespace :: proc(r: rune) -> bool {
    whitespace_chars := " \t\r\f\v\n"
    for w in whitespace_chars {
        if r == w do return true
    }
    return false
}

is_symbolic :: proc(r: rune) -> bool {
    symbolic_chars := "!@#$%^&*`~-+=/|\\?<>:"
    for s in symbolic_chars {
        if r == s do return true
    }
    return false
}

is_alpha :: proc(r: rune) -> bool {
    return (r >= 'A' && r <= 'Z') || (r >= 'a' && r <= 'z') || r == '\''
}

is_numeric :: proc(r: rune) -> bool {
    return r >= '0' && r <= '9'
}

is_alphanumeric :: proc(r: rune) -> bool {
    return is_alpha(r) || is_numeric(r) || r == '_'
}

tokenize :: proc(script: ^string) -> [dynamic]Token {
    reader: strings.Reader
    strings.reader_init(&reader, script^)
    lexer := Lexer{reader, 0, .NONE, 1}
    
    tokens := make([dynamic]Token)

    for true {
        curr_pos := int(lexer.reader.i);

        r, r_size, err := strings.reader_read_rune(&lexer.reader)
        if err != nil {
            fmt.println("error: ", err)
            break
        }

        if r == '\n' do lexer.line += 1

        step_rune(&lexer, &tokens, r, curr_pos)
    }

    step_rune(&lexer, &tokens, rune('\n'), len(script))

    return tokens
}

step_rune :: proc(lexer: ^Lexer, tokens: ^[dynamic]Token, r: rune, curr_pos: int) {
    #partial switch lexer.type {
    case .ALPHANUMERIC:
        if !is_alphanumeric(r) {
            lexer.type = .NONE
            text := lexer.reader.s[lexer.token_start : curr_pos]
            append(tokens, Token{.ALPHANUMERIC, strings.clone(text), lexer.line})
        }
    case .SYMBOLIC:
        if !is_symbolic(r) {
            lexer.type = .NONE
            text := lexer.reader.s[lexer.token_start : curr_pos]
            append(tokens, Token{.SYMBOLIC, strings.clone(text), lexer.line})
        }
    }
    
    if lexer.type == .NONE {
        if is_alphanumeric(r) {
            lexer.type = .ALPHANUMERIC
        }
        else if is_symbolic(r) {
            lexer.type = .SYMBOLIC
        }
        else if strings.index_rune("()[]{},;.", r) != -1 {
            append(tokens, Token{.SPECIAL_CHAR, fmt.tprint(r), lexer.line})
        }

        if (lexer.type != .NONE) {
            lexer.token_start = curr_pos
        }
    }
}
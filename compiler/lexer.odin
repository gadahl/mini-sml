package compiler

import "core:fmt"
import "core:strings"


main :: proc() {
    script := \
`(* A helper function for the main Fibonacci function *) 
fun fib' 0 _ b = b 
  | fib' n a b = fib' (n-1) (a+b) a; 
(* Computes the nth Fibonacci number (* fib 0 -> 0, fib 1 -> 1, ... *) *)
fun fib n = fib' n 1 0; 
fib 10;`

    basic_tokens := basic_tokenize(&script)
    defer {
        for token in basic_tokens {
            delete(token.text)
        }
        delete(basic_tokens)
    }

    for token in basic_tokens {
        switch token.type {
        case .ALPHANUMERIC: 
            fmt.println("ALPHANUM", token.text)
        case .SYMBOLIC: 
            fmt.println("SYMBOLIC", token.text)
        case .SPECIAL_CHAR: 
            fmt.println("SPECIAL ", token.text)
        case .COMMENT:
            fmt.println("COMMENT ", token.text)
        case .STRING_LIT: 
            fmt.println("STRING  ", token.text)
        case .NONE: 
            fmt.println("NONE")
        }
    }

    full_tokens := full_token_pass(basic_tokens)
    defer {
        for token in full_tokens {
            delete(token.text)
        }
        delete(full_tokens)
    }

    fmt.println()

    for token in full_tokens {
        switch token.type {
        case .STRING_LIT: 
            fmt.println("STRING  ", token.text)
        case .RESERVED_KEYWORD:
            fmt.println("RESERVED", token.text)
        case .TYPE_VAR:
            fmt.println("TYPEVAR ", token.text)
        case .ALPHANUM_IDENT:
            fmt.println("ALPHA_ID", token.text)
        case .SYMBOLIC_IDENT:
            fmt.println("SYMBOLIC", token.text)
        case .COMMENT:
            fmt.println("COMMENT ", token.text)
        case .INTEGER_LIT:
            fmt.println("INT LIT ", token.text)
        case .REAL_LIT:
            fmt.println("REAL LIT", token.text)
        }
    }
}

whitespace_chars :: " \t\r\f\v\n"
symbolic_chars :: "!@#$%^&*`~-+=/|\\?<>:"
reserved_chars :: "()[]{},;."
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


Full_Token_Type :: enum {
    RESERVED_KEYWORD,
    TYPE_VAR,
    ALPHANUM_IDENT,
    SYMBOLIC_IDENT,
    INTEGER_LIT,
    STRING_LIT,
    REAL_LIT,
    COMMENT,
}

Full_Token :: struct {
    type: Full_Token_Type,
    text: string,
    line: int,
}

alpha_keywords: []string: { 
    "_", "abstype", "and", "andalso", "as", "case", "do", "datatype", 
    "else", "end", "exception", "fn", "fun", "handle", "if", "in", "infix", "infixr", 
    "let", "local", "nonfix", "of", "op", "open", "orelse", 
    "raise", "rec", "then", "type", "val", "with", "withtype", "while",
}
symbolic_keywords: []string: { 
   ":", "|", "=", "=>", "->", "#",
}

full_token_pass :: proc(basic_tokens: [dynamic]Basic_Token) -> [dynamic]Full_Token {
    full_tokens := make([dynamic]Full_Token)
    dot_count := 0
    prev_line_num := 1

    for token in basic_tokens {
        if (len(token.text) == 0) {
            panic(fmt.tprintf("basic token is missing text field: %#v", token))
        }

        // handle the reserved words "." and "..."
        if token.type == .SPECIAL_CHAR && token.text[0] == '.' {
            dot_count += 1
        }
        else if dot_count != 0 {
            switch dot_count {
                case 1: append(&full_tokens, Full_Token{.RESERVED_KEYWORD, ".", prev_line_num})
                case 3: append(&full_tokens, Full_Token{.RESERVED_KEYWORD, "...", prev_line_num})
                case:   fmt.printfln("Error: cannot parse %d sequential '.' characters", dot_count)
            }
            dot_count = 0
        }

        token_switch: switch token.type {
        case .NONE:
            // this should never happen, so it makes sense to panic here
            panic(fmt.tprintf("basic token has type .NONE: %#v", token))

        case .ALPHANUMERIC:
            for keyword in alpha_keywords {
                if strings.compare(token.text, keyword) == 0 {
                    append(&full_tokens, Full_Token{.RESERVED_KEYWORD, keyword, token.line})
                    break token_switch
                }
            }
            
            // at this point, the token needs to be a valid alphanum identifier
            
            first_char: u8 = token.text[0]

            if first_char == '\'' {
                append(&full_tokens, Full_Token{.TYPE_VAR, strings.clone(token.text), token.line})
            }
            else if is_numeric(first_char) {
                // TODO: handle number parsing
                append(&full_tokens, Full_Token{.INTEGER_LIT, strings.clone(token.text), token.line})
            }
            else {
                // first_char is in a-z or A-Z
                append(&full_tokens, Full_Token{.ALPHANUM_IDENT, strings.clone(token.text), token.line})
            }

        case .SYMBOLIC:
            for keyword in symbolic_keywords {
                if strings.compare(token.text, keyword) == 0 {
                    append(&full_tokens, Full_Token{.RESERVED_KEYWORD, keyword, token.line})
                    break token_switch
                }
            }
            // at this point, the token needs to be a valid symbolic identifier
            append(&full_tokens, Full_Token{.SYMBOLIC_IDENT, strings.clone(token.text), token.line})

        case .SPECIAL_CHAR:
            // skip already-handled '.' case
            if token.text[0] != '.' {
                append(&full_tokens, Full_Token{.RESERVED_KEYWORD, strings.clone(token.text), token.line})
            }
            
        case .COMMENT:
            append(&full_tokens, Full_Token{.COMMENT, strings.clone(token.text), token.line})
            
        case .STRING_LIT:
            append(&full_tokens, Full_Token{.STRING_LIT, strings.clone(token.text), token.line})
        }

        prev_line_num = token.line
    }
    return full_tokens
}
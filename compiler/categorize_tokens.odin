package compiler

import "core:fmt"
import "core:strings"


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


Token2_Type :: enum {
    RESERVED_KEYWORD,
    TYPE_VAR,
    ALPHANUM_IDENT,
    SYMBOLIC_IDENT,
    INTEGER_LIT,
    STRING_LIT,
    REAL_LIT,
    COMMENT,
}

Token2 :: struct {
    type: Token2_Type,
    text: string,
    line: int,
}

// Token_Value :: union {
//     i32,
//     string,
//     f32,
//     No_Value,
// }

// No_Value :: struct {}

token2_pass :: proc(basic_tokens: [dynamic]Token1) -> [dynamic]Token2 {
    token2s := make([dynamic]Token2)
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
                case 1: append(&token2s, Token2{.RESERVED_KEYWORD, ".", prev_line_num})
                case 3: append(&token2s, Token2{.RESERVED_KEYWORD, "...", prev_line_num})
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
                    append(&token2s, Token2{.RESERVED_KEYWORD, keyword, token.line})
                    break token_switch
                }
            }
            
            // at this point, the token needs to be a valid alphanum identifier
            
            first_char: u8 = token.text[0]

            if first_char == '\'' {
                append(&token2s, Token2{.TYPE_VAR, strings.clone(token.text), token.line})
            }
            else if is_numeric(first_char) {
                // TODO: handle number parsing
                append(&token2s, Token2{.INTEGER_LIT, strings.clone(token.text), token.line})
            }
            else {
                // first_char is in a-z or A-Z
                append(&token2s, Token2{.ALPHANUM_IDENT, strings.clone(token.text), token.line})
            }

        case .SYMBOLIC:
            for keyword in symbolic_keywords {
                if strings.compare(token.text, keyword) == 0 {
                    append(&token2s, Token2{.RESERVED_KEYWORD, keyword, token.line})
                    break token_switch
                }
            }
            // at this point, the token needs to be a valid symbolic identifier
            append(&token2s, Token2{.SYMBOLIC_IDENT, strings.clone(token.text), token.line})

        case .SPECIAL_CHAR:
            // skip already-handled '.' case
            if token.text[0] != '.' {
                append(&token2s, Token2{.RESERVED_KEYWORD, strings.clone(token.text), token.line})
            }
            
        case .COMMENT:
            append(&token2s, Token2{.COMMENT, strings.clone(token.text), token.line})
            
        case .STRING_LIT:
            append(&token2s, Token2{.STRING_LIT, strings.clone(token.text), token.line})
        }

        prev_line_num = token.line
    }
    return token2s
}
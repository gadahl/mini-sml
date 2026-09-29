package compiler

import "core:fmt"


main :: proc() {
    script := `(*"*) (* "abc" "123 *) " lmnop )* "`

    tokens := tokenize(&script)
    defer delete_tokens(tokens)

    display_tokens(tokens[:])
}
main2 :: proc() {
    script := \
`(* A helper function for the main Fibonacci function *) 
fun fib' 0 _ b = b 
| fib' n a b = fib' (n-1) (a+b) a; 
(* Computes the nth Fibonacci number (* fib 0 -> 0, fib 1 -> 1, ... *) *)
fun fib n = fib' n 1 0; 
fib 10;
val str = "h\069llo \\ \"world\"";`

    tokens := tokenize(&script)
    defer delete_tokens(tokens)

    display_tokens(tokens[:])
}

display_tokens :: proc(tokens: []Token) {
    for token in tokens {
        switch token.type {
        case .RESERVED_KEYWORD:
            fmt.println("KEYWORD ", token.text)
            if token.text[0] == ';' do fmt.println()
        case .WILDCARD:
            fmt.println("WILDCARD", token.text)
        case .TYPE_VAR:
            fmt.println("TYPEVAR ", token.text)
        case .ALPHANUM_IDENT:
            fmt.println("ALPHA_ID", token.text)
        case .SYMBOLIC_IDENT:
            fmt.println("SYMBOLIC", token.text)
        case .COMMENT:
            fmt.println("COMMENT ", token.text)
        case .INTEGER_LIT:
            fmt.println("INT LIT ", token.text, "-->", token.literal_value)
        case .REAL_LIT:
            fmt.println("REAL LIT", token.text, "-->", token.literal_value)
        case .STRING_LIT: 
            fmt.println("STRING  ", token.text, "-->", token.literal_value)
        }
    }
}

delete_tokens :: proc(tokens: [dynamic]Token) {
    for token in tokens {
        delete(token.text)
    }
    delete(tokens)
}
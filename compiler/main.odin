package compiler

import "core:fmt"


main :: proc() {
    fmt.println(int(95-64))
    script := \
`(* A helper function for the main Fibonacci function *) 
fun fib' 0 _ b = b 
  | fib' n a b = fib' (n-1) (a+b) a; 
(* Computes the nth Fibonacci number (* fib 0 -> 0, fib 1 -> 1, ... *) *)
fun fib n = fib' n 1 0; 
fib 10;
val str = "h\069llo \\ \"world\"";`

    token1s := tokenize(&script)
    defer {
        for token in token1s {
            delete(token.text)
        }
        delete(token1s)
    }

    fmt.println("---- Pass 1 ----")

    for token in token1s {
        switch token.type {
        case .ALPHANUMERIC: 
            fmt.println("ALPHANUM", token.text)
        case .SYMBOLIC: 
            fmt.println("SYMBOLIC", token.text)
        case .SPECIAL_CHAR: 
            fmt.println("SPECIAL ", token.text)
            if token.text[0] == ';' do fmt.println()
        case .COMMENT:
            fmt.println("COMMENT ", token.text)
        case .STRING_LIT: 
            fmt.println("STRING  ", token.text)
        case .NONE: 
            fmt.println("NONE")
        }
    }

    token2s := token2_pass(token1s)
    defer {
        for token in token2s {
            delete(token.text)
        }
        delete(token2s)
    }

    fmt.println()
    fmt.println("---- Pass 2 ----")

    for token in token2s {
        switch token.type {
        case .RESERVED_KEYWORD:
            fmt.println("RESERVED", token.text)
            if token.text[0] == ';' do fmt.println()
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

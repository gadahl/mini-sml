package compiler

import "core:fmt"
import "../lexer"
import "../parser"
import "../ast"


main :: proc() {
    test_lambda_fn_parsing()
}

test_lambda_fn_parsing :: proc() {
    script := `
    val sqr = fn x => x*x;

    val is_empty = 
        fn nil => "yes"
         | xs  => "no"
    `
    test_script(&script)
}

test_while_case_parsing :: proc() {
    script := `
    val x' = while x < limit
    do increase x;

    val y' = case y of 
        nothing => ""
        | some_n => tostring n;
    `
    test_script(&script)
}

test_if_parsing :: proc() {
    script := `
    val v1 = 9;
    val v2 = if v1 < 5 then 5 else v1;
    `
    test_script(&script)
}

test_infix_decl_parsing :: proc() {
    script := `
    infix 7 * /;
    infixr + -;
    fun f a b = a+a*b+b;
    val k = f 3 4 + f 4 3;
    `
    test_script(&script)
}

test_fun_decl_parsing :: proc() {
    script := `
    fun f a b = a + b + a*b;
    fun g x = f x 2;
    fun h 0 = 1
      | h n = h (n-1) + 1;
    fun h' 0 = 1
      | h' 1 = 3
      | h' 2 = 5
      | h' n = h (n-1) + 1;
    val k = g 3 + f 4 3;
    `
    test_script(&script)
}

test_append_marks_function :: proc() {
    script := `
    fun append_marks str = let
        val cs = explode str;
        val cs' = cs @ "...?!";
        in implode cs
    end
    `
    test_script(&script)
}

test_val_decl_parsing :: proc() {
    script := `
    val a = 5 : int; 
    val b: real = ~3.001; 
    val c = "hello"; 
    val ~1 = 0;
    val x = a + b;
    val y = x / a * b;
    val z = f x;
    val g = f : int -> real
    `
    test_script(&script)
}

test_complex_val_decl_parsing :: proc() {
    script := `
    val x: real = 0.05;
    val (m, n): int * int = (123, ~25);
    val y: real = 1E~9;
    val z: real = ~540.01E6;
    val rect = {x= ~1.0, y=0.0, w=3.5, h=6.0}; 
    `
    test_script(&script)
}

test_type_parsing :: proc() {
    script := `
    val v1: a b c (d * e) F * g * h i (j K) L -> m -> n -> (o -> p q r S) T = 0;
    val v2: (a -> b -> c) -> a * b -> c = 0;
    val v3: x * y list -> (a * b) list = 0;
    `
    test_script(&script)
}

test_script :: proc(script: ^string) {
    tokens := lexer.tokenize(script)
    defer delete_tokens(tokens)

    display_tokens(tokens[:])

    tree, err := parser.parse_program(tokens[:])
    if err != nil {
        fmt.println("error:", err.message)
    }
    else {
        ast.print_tree(tree.base_node)
    }
}

token_test_1 :: proc() {
    script := \
    `(* A helper function for the main Fibonacci function *) 
    fun fib' 0 _ b = b 
    | fib' n a b = fib' (n-1) (a+b) a; 
    (* Computes the nth Fibonacci number (* fib 0 -> 0, fib 1 -> 1, ... *) *)
    fun fib n = fib' n 1 0; 
    fib 10;
    val str = "h\069llo \\ \"world\"";`

    tokens := lexer.tokenize(&script)
    defer delete_tokens(tokens)

    display_tokens(tokens[:])
}

token_test_2 :: proc() {
    script := `(*"*) (* "abc" "123 *) " lmnop )* "`

    tokens := lexer.tokenize(&script)
    defer delete_tokens(tokens)

    display_tokens(tokens[:])
}

token_test_3 :: proc() {
    script := `
    ~1~2;
    ~3.~4;
    5.~6;
    7e8;
    .99;
    12.;
    3.4.5;
    6E7.8;
    1E2E3;
    4x;
    `
    tokens := lexer.tokenize(&script)
    defer delete_tokens(tokens)

    display_tokens(tokens[:])
}

display_tokens :: proc(tokens: []lexer.Token) {
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
            fmt.printfln("STRING   %s --> `%s`", token.text, token.literal_value)
        case .EOF: 
            fmt.println("EOF     ")
        }
    }
    fmt.println()
}

delete_tokens :: proc(tokens: [dynamic]lexer.Token) {
    for token in tokens {
        delete(token.text)
    }
    delete(tokens)
}
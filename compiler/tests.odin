package compiler

import "core:testing"
import "core:time"
import "base:runtime"

@(test)
test_tokenize_empty :: proc(t: ^testing.T) {
    str := ""
    test_token_output(t, #location(), &str, {})
}

@(test)
test_tokenize_symbolic :: proc(t: ^testing.T) {
    str := "<#>"
    test_token_output(t, #location(), &str, {
        {.SYMBOLIC_IDENT, "<#>", No_Value{}, 1},
    })
}

@(test)
test_tokenize_alphanum :: proc(t: ^testing.T) {
    str := "abc_123'"
    test_token_output(t, #location(), &str, {
        {.ALPHANUM_IDENT, "abc_123'", Undefined{}, 1},
    })
}

@(test)
test_tokenize_special_char :: proc(t: ^testing.T) {
    str := "."
    test_token_output(t, #location(), &str, {
        {.RESERVED_KEYWORD, ".", No_Value{}, 1},
    })
}

@(test)
test_tokenize_spaced :: proc(t: ^testing.T) {
    str := "fun h x y0 = f x + g y0 - 1 ;"
    test_token_output(t, #location(), &str, {
        {.RESERVED_KEYWORD, "fun",  Undefined{}, 1},
        {.ALPHANUM_IDENT,   "h",    Undefined{}, 1},
        {.ALPHANUM_IDENT,   "x",    Undefined{}, 1},
        {.ALPHANUM_IDENT,   "y0",   Undefined{}, 1},
        {.RESERVED_KEYWORD, "=",    No_Value{}, 1},
        {.ALPHANUM_IDENT,   "f",    Undefined{}, 1},
        {.ALPHANUM_IDENT,   "x",    Undefined{}, 1},
        {.SYMBOLIC_IDENT,   "+",    No_Value{}, 1},
        {.ALPHANUM_IDENT,   "g",    Undefined{}, 1},
        {.ALPHANUM_IDENT,   "y0",   Undefined{}, 1},
        {.SYMBOLIC_IDENT,   "-",    No_Value{}, 1},
        {.INTEGER_LIT,      "1",    1,          1},
        {.RESERVED_KEYWORD, ";",    No_Value{}, 1},
    })
}

@(test)
test_tokenize_squished :: proc(t: ^testing.T) {
    str := "funhxy0=fx+gy0-1;"
    test_token_output(t, #location(), &str, {
        {.ALPHANUM_IDENT,   "funhxy0",  Undefined{}, 1},
        {.RESERVED_KEYWORD, "=",        No_Value{}, 1},
        {.ALPHANUM_IDENT,   "fx",       Undefined{}, 1},
        {.SYMBOLIC_IDENT,   "+",        No_Value{}, 1},
        {.ALPHANUM_IDENT,   "gy0",      Undefined{}, 1},
        {.SYMBOLIC_IDENT,   "-",        No_Value{}, 1},
        {.INTEGER_LIT,      "1",        1,          1},
        {.RESERVED_KEYWORD, ";",        No_Value{}, 1},
    })
}

@(test)
test_tokenize_ellipsis :: proc(t: ^testing.T) {
    str := "..."
    test_token_output(t, #location(), &str, {
        {.RESERVED_KEYWORD, "...", No_Value{}, 1},
    })
}

@(test)
test_tokenize_string :: proc(t: ^testing.T) {
    str := `"hello world"`
    test_token_output(t, #location(), &str, {
        {.STRING_LIT, `"hello world"`, "hello world", 1},
    })
}

@(test)
test_tokenize_separated_string :: proc(t: ^testing.T) {
    str := `"hello"" world"`
    test_token_output(t, #location(), &str, {
        {.STRING_LIT, `"hello"`, "hello", 1},
        {.STRING_LIT, `" world"`, " world", 1},
    })
}

@(test)
test_tokenize_escaped_string :: proc(t: ^testing.T) {
    str := `"hello\"\" world"`
    test_token_output(t, #location(), &str, {
        {.STRING_LIT, `"hello\"\" world"`, "hello\"\" world", 1},
    })
}

@(test)
test_tokenize_ctrl_string :: proc(t: ^testing.T) {
    str := `"lorem ipsum \^C" ++ "\^R" ++ str3`
    test_token_output(t, #location(), &str, {
        {.STRING_LIT,       `"lorem ipsum \^C"`,    "lorem ipsum \x03", 1},
        {.SYMBOLIC_IDENT,   `++`,                   No_Value{},         1},
        {.STRING_LIT,       `"\^R"`,                "\x12",             1},
        {.SYMBOLIC_IDENT,   `++`,                   No_Value{},         1},
        {.ALPHANUM_IDENT,   `str3`,                 Undefined{},        1},
    })
}

@(test)
test_tokenize_ctrl_string_bounds :: proc(t: ^testing.T) {
    str := `"\^@\^_"`
    test_token_output(t, #location(), &str, {
        {.STRING_LIT, `"\^@\^_"`, "\x00\x1F", 1},
    })
}

@(test)
test_tokenize_digit_string :: proc(t: ^testing.T) {
    str := `"\000\255"`
    test_token_output(t, #location(), &str, {
        {.STRING_LIT, `"\000\255"`, "\x00\xFF", 1},
    })
}

@(test)
test_tokenize_comment :: proc(t: ^testing.T) {
    str := `(* comment *)`
    test_token_output(t, #location(), &str, {
        {.COMMENT, `(* comment *)`, No_Value{}, 1},
    })
}

@(test)
test_tokenize_comments_and_nums :: proc(t: ^testing.T) {
    str := `123 (*25*)0 (**) 34(* 8 *) 9`
    test_token_output(t, #location(), &str, {
        {.INTEGER_LIT,  `123`,      123,        1},
        {.COMMENT,      `(*25*)`,   No_Value{}, 1},
        {.INTEGER_LIT,  `0`,        0,          1},
        {.COMMENT,      `(**)`,     No_Value{}, 1},
        {.INTEGER_LIT,  `34`,       34,         1},
        {.COMMENT,      `(* 8 *)`,  No_Value{}, 1},
        {.INTEGER_LIT,  `9`,        9,          1},
    })
}

@(test)
test_tokenize_nested_comments :: proc(t: ^testing.T) {
    str := `(* comment (* layer 2 *) *)`
    test_token_output(t, #location(), &str, {
        {.COMMENT, `(* comment (* layer 2 *) *)`, No_Value{}, 1},
    })
}

@(test)
test_tokenize_squashed_comments :: proc(t: ^testing.T) {
    str := `(*(**)(**)*)(*)*)`
    test_token_output(t, #location(), &str, {
        {.COMMENT, `(*(**)(**)*)`, No_Value{}, 1},
        {.COMMENT, `(*)*)`, No_Value{}, 1},
    })
}

@(test)
test_tokenize_comments_and_strings :: proc(t: ^testing.T) {
    str := `(*"*) (* "abc" "123 *) " lmnop )* "`
    test_token_output(t, #location(), &str, {
        {.COMMENT,    `(*"*)`,            No_Value{}, 1},
        {.COMMENT,    `(* "abc" "123 *)`, No_Value{}, 1},
        {.STRING_LIT, `" lmnop )* "`,     " lmnop )* ", 1},
    })
}

@(test)
test_tokenize_keyword :: proc(t: ^testing.T) {
    str := "{"
    test_token_output(t, #location(), &str, {
        {.RESERVED_KEYWORD, "{", No_Value{}, 1},
    })
}

@(test)
test_tokenize_wildcard :: proc(t: ^testing.T) {
    str := "_"
    test_token_output(t, #location(), &str, {
        {.WILDCARD, "_", No_Value{}, 1},
    })
}



test_token_output :: proc(t: ^testing.T, loc: runtime.Source_Code_Location, input: ^string, expected: []Token) {
    testing.set_fail_timeout(t, 1 * time.Second)

    tokens := tokenize(input)
    defer {
        for token in tokens {
            delete(token.text)
            #partial switch value in token.literal_value{
                case string: delete(value)
            }
        }
        delete(tokens)
    }

    testing.expect_value(t, len(tokens), len(expected), loc)
    
    for token, i in tokens {
        expected_token := expected[i]
        testing.expect_value(t, token.type, expected_token.type, loc)
        testing.expect_value(t, token.text, expected_token.text, loc)
        testing.expect_value(t, token.line, expected_token.line, loc)
    }
}

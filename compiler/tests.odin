package compiler

import "core:testing"
import "core:time"
import "base:runtime"

@(test)
test_tokenize1_empty :: proc(t: ^testing.T) {
    str := ""
    test_token1_output(t, #location(), &str, {})
}

@(test)
test_tokenize1_symbolic :: proc(t: ^testing.T) {
    str := "<#>"
    test_token1_output(t, #location(), &str, {
        {.SYMBOLIC, "<#>", No_Value{}, 1},
    })
}

@(test)
test_tokenize1_alphanum :: proc(t: ^testing.T) {
    str := "abc_123'"
    test_token1_output(t, #location(), &str, {
        {.ALPHANUMERIC, "abc_123'", Undefined{}, 1},
    })
}

@(test)
test_tokenize1_special_char :: proc(t: ^testing.T) {
    str := "."
    test_token1_output(t, #location(), &str, {
        {.SPECIAL_CHAR, ".", No_Value{}, 1},
    })
}

@(test)
test_tokenize1_spaced :: proc(t: ^testing.T) {
    str := "fun h x y0 = f x + g y0 - 1 ;"
    test_token1_output(t, #location(), &str, {
        {.ALPHANUMERIC, "fun",  Undefined{}, 1},
        {.ALPHANUMERIC, "h",    Undefined{}, 1},
        {.ALPHANUMERIC, "x",    Undefined{}, 1},
        {.ALPHANUMERIC, "y0",   Undefined{}, 1},
        {.SYMBOLIC,     "=",    No_Value{}, 1},
        {.ALPHANUMERIC, "f",    Undefined{}, 1},
        {.ALPHANUMERIC, "x",    Undefined{}, 1},
        {.SYMBOLIC,     "+",    No_Value{}, 1},
        {.ALPHANUMERIC, "g",    Undefined{}, 1},
        {.ALPHANUMERIC, "y0",   Undefined{}, 1},
        {.SYMBOLIC,     "-",    No_Value{}, 1},
        {.ALPHANUMERIC, "1",    Undefined{}, 1},
        {.SPECIAL_CHAR, ";",    No_Value{}, 1},
    })
}

@(test)
test_tokenize1_squished :: proc(t: ^testing.T) {
    str := "funhxy0=fx+gy0-1;"
    test_token1_output(t, #location(), &str, {
        {.ALPHANUMERIC, "funhxy0",  Undefined{}, 1},
        {.SYMBOLIC,     "=",        No_Value{}, 1},
        {.ALPHANUMERIC, "fx",       Undefined{}, 1},
        {.SYMBOLIC,     "+",        No_Value{}, 1},
        {.ALPHANUMERIC, "gy0",      Undefined{}, 1},
        {.SYMBOLIC,     "-",        No_Value{}, 1},
        {.ALPHANUMERIC, "1",        Undefined{}, 1},
        {.SPECIAL_CHAR, ";",        No_Value{}, 1},
    })
}

@(test)
test_tokenize1_ellipsis :: proc(t: ^testing.T) {
    str := "..."
    test_token1_output(t, #location(), &str, {
        {.SPECIAL_CHAR, ".", No_Value{}, 1},
        {.SPECIAL_CHAR, ".", No_Value{}, 1},
        {.SPECIAL_CHAR, ".", No_Value{}, 1},
    })
}

@(test)
test_tokenize1_string :: proc(t: ^testing.T) {
    str := `"hello world"`
    test_token1_output(t, #location(), &str, {
        {.STRING_LIT, `"hello world"`, "hello world", 1},
    })
}

@(test)
test_tokenize1_separated_string :: proc(t: ^testing.T) {
    str := `"hello"" world"`
    test_token1_output(t, #location(), &str, {
        {.STRING_LIT, `"hello"`, "hello", 1},
        {.STRING_LIT, `" world"`, " world", 1},
    })
}

@(test)
test_tokenize1_escaped_string :: proc(t: ^testing.T) {
    str := `"hello\"\" world"`
    test_token1_output(t, #location(), &str, {
        {.STRING_LIT, `"hello\"\" world"`, "hello\"\" world", 1},
    })
}

@(test)
test_tokenize_ctrl_string :: proc(t: ^testing.T) {
    str := `"lorem ipsum \^C" ++ "\^R" ++ str3`
    test_token1_output(t, #location(), &str, {
        {.STRING_LIT, `"lorem ipsum \^C"`, "lorem ipsum \x03", 1},
        {.SYMBOLIC, `++`, No_Value{}, 1},
        {.STRING_LIT, `"\^R"`, "\x12", 1},
        {.SYMBOLIC, `++`, No_Value{}, 1},
        {.ALPHANUMERIC, `str3`, Undefined{}, 1},
    })
}

@(test)
test_tokenize_ctrl_string_bounds :: proc(t: ^testing.T) {
    str := `"\^@\^_"`
    test_token1_output(t, #location(), &str, {
        {.STRING_LIT, `"\^@\^_"`, "\x00\x1F", 1},
    })
}

@(test)
test_tokenize_digit_string :: proc(t: ^testing.T) {
    str := `"\000\255"`
    test_token1_output(t, #location(), &str, {
        {.STRING_LIT, `"\000\255"`, "\x00\xFF", 1},
    })
}

@(test)
test_tokenize_comment :: proc(t: ^testing.T) {
    str := `(* comment *)`
    test_token1_output(t, #location(), &str, {
        {.COMMENT, `(* comment *)`, No_Value{}, 1},
    })
}

@(test)
test_tokenize_comments_and_nums :: proc(t: ^testing.T) {
    str := `123 (*25*)0 (**) 34(* 8 *) 9`
    test_token1_output(t, #location(), &str, {
        {.ALPHANUMERIC, `123`,      Undefined{}, 1},
        {.COMMENT,      `(*25*)`,   No_Value{}, 1},
        {.ALPHANUMERIC, `0`,        Undefined{}, 1},
        {.COMMENT,      `(**)`,     No_Value{}, 1},
        {.ALPHANUMERIC, `34`,       Undefined{}, 1},
        {.COMMENT,      `(* 8 *)`,  No_Value{}, 1},
        {.ALPHANUMERIC, `9`,        Undefined{}, 1},
    })
}

@(test)
test_tokenize_nested_comments :: proc(t: ^testing.T) {
    str := `(* comment (* layer 2 *) *)`
    test_token1_output(t, #location(), &str, {
        {.COMMENT, `(* comment (* layer 2 *) *)`, No_Value{}, 1},
    })
}

@(test)
test_tokenize_squashed_comments :: proc(t: ^testing.T) {
    str := `(*(**)(**)*)(*)*)`
    test_token1_output(t, #location(), &str, {
        {.COMMENT, `(*(**)(**)*)`, No_Value{}, 1},
        {.COMMENT, `(*)*)`, No_Value{}, 1},
    })
}

@(test)
test_tokenize_comments_and_strings :: proc(t: ^testing.T) {
    str := `(*"*) (* "abc" "123 *) " lmnop )* "`
    test_token1_output(t, #location(), &str, {
        {.COMMENT,    `(*"*)`,            No_Value{}, 1},
        {.COMMENT,    `(* "abc" "123 *)`, No_Value{}, 1},
        {.STRING_LIT, `" lmnop )* "`,     " lmnop )* ", 1},
    })
}



@(test)
test_tokenize2_keyword :: proc(t: ^testing.T) {
    str := "{"
    test_token2_output(t, #location(), &str, {
        {.RESERVED_KEYWORD, "{", No_Value{}, 1},
    })
}



test_token1_output :: proc(t: ^testing.T, loc: runtime.Source_Code_Location, input: ^string, expected: []Token1) {
    testing.set_fail_timeout(t, 3 * time.Second)

    token1s := tokenize(input)
    defer {
        for token in token1s {
            delete(token.text)
            #partial switch value in token.literal_value{
                case string: delete(value)
            }
        }
        delete(token1s)
    }

    testing.expect_value(t, len(token1s), len(expected))
    
    for token1, i in token1s {
        expected_token := expected[i]
        testing.expect_value(t, token1.type, expected_token.type, loc)
        testing.expect_value(t, token1.text, expected_token.text, loc)
        testing.expect_value(t, token1.literal_value, expected_token.literal_value, loc)
        testing.expect_value(t, token1.line, expected_token.line, loc)
    }
}

test_token2_output :: proc(t: ^testing.T, loc: runtime.Source_Code_Location, input: ^string, expected: []Token2) {
    testing.set_fail_timeout(t, 3 * time.Second)

    token1s := tokenize(input)
    defer {
        for token in token1s {
            delete(token.text)
            #partial switch value in token.literal_value{
                case string: delete(value)
            }
        }
        delete(token1s)
    }

    token2s := token2_pass(token1s)
    defer {
        for token in token2s {
            delete(token.text)
            #partial switch value in token.literal_value{
                case string: delete(value)
            }
        }
        delete(token2s)
    }

    testing.expect_value(t, len(token2s), len(expected))
    
    for token2, i in token2s {
        expected_token := expected[i]
        testing.expect_value(t, token2.type, expected_token.type, loc)
        testing.expect_value(t, token2.text, expected_token.text, loc)
        testing.expect_value(t, token2.line, expected_token.line, loc)
    }
}

package compiler

import "core:testing"
import "core:time"

@(test)
test_tokenize_basic_empty :: proc(t: ^testing.T) {
    str := ""
    test_basic_token_output(t, &str, {})
}

@(test)
test_tokenize_basic_symbolic :: proc(t: ^testing.T) {
    str := "<#>"
    test_basic_token_output(t, &str, {
        {.SYMBOLIC, "<#>", 1},
    })
}

@(test)
test_tokenize_basic_alphanum :: proc(t: ^testing.T) {
    str := "abc_123'"
    test_basic_token_output(t, &str, {
        {.ALPHANUMERIC, "abc_123'", 1},
    })
}

@(test)
test_tokenize_basic_special_char :: proc(t: ^testing.T) {
    str := "."
    test_basic_token_output(t, &str, {
        {.SPECIAL_CHAR, ".", 1},
    })
}

@(test)
test_tokenize_basic_spaced :: proc(t: ^testing.T) {
    str := "fun h x y0 = f x + g y0 - 1 ;"
    test_basic_token_output(t, &str, {
        {.ALPHANUMERIC, "fun", 1},
        {.ALPHANUMERIC, "h", 1},
        {.ALPHANUMERIC, "x", 1},
        {.ALPHANUMERIC, "y0", 1},
        {.SYMBOLIC, "=", 1},
        {.ALPHANUMERIC, "f", 1},
        {.ALPHANUMERIC, "x", 1},
        {.SYMBOLIC, "+", 1},
        {.ALPHANUMERIC, "g", 1},
        {.ALPHANUMERIC, "y0", 1},
        {.SYMBOLIC, "-", 1},
        {.ALPHANUMERIC, "1", 1},
        {.SPECIAL_CHAR, ";", 1},
    })
}

@(test)
test_tokenize_basic_squished :: proc(t: ^testing.T) {
    str := "funhxy0=fx+gy0-1;"
    test_basic_token_output(t, &str, {
        {.ALPHANUMERIC, "funhxy0", 1},
        {.SYMBOLIC, "=", 1},
        {.ALPHANUMERIC, "fx", 1},
        {.SYMBOLIC, "+", 1},
        {.ALPHANUMERIC, "gy0", 1},
        {.SYMBOLIC, "-", 1},
        {.ALPHANUMERIC, "1", 1},
        {.SPECIAL_CHAR, ";", 1},
    })
}

@(test)
test_tokenize_basic_ellipsis :: proc(t: ^testing.T) {
    str := "..."
    test_basic_token_output(t, &str, {
        {.SPECIAL_CHAR, ".", 1},
        {.SPECIAL_CHAR, ".", 1},
        {.SPECIAL_CHAR, ".", 1},
    })
}

@(test)
test_tokenize_basic_string :: proc(t: ^testing.T) {
    str := `"hello world"`
    test_basic_token_output(t, &str, {
        {.STRING_LIT, `"hello world"`, 1},
    })
}

@(test)
test_tokenize_basic_separated_string :: proc(t: ^testing.T) {
    str := `"hello"" world"`
    test_basic_token_output(t, &str, {
        {.STRING_LIT, `"hello"`, 1},
        {.STRING_LIT, `" world"`, 1},
    })
}

@(test)
test_tokenize_basic_escaped_string :: proc(t: ^testing.T) {
    str := `"hello\"\" world"`
    test_basic_token_output(t, &str, {
        {.STRING_LIT, `"hello\"\" world"`, 1},
    })
}

@(test)
test_tokenize_ctrl_string :: proc(t: ^testing.T) {
    str := `"lorem ipsum \^C" ++ "\^R" ++ str3`
    test_basic_token_output(t, &str, {
        {.STRING_LIT, `"lorem ipsum \^C"`, 1},
        {.SYMBOLIC, `++`, 1},
        {.STRING_LIT, `"\^R"`, 1},
        {.SYMBOLIC, `++`, 1},
        {.ALPHANUMERIC, `str3`, 1},
    })
}

@(test)
test_tokenize_ctrl_string_bounds :: proc(t: ^testing.T) {
    str := `"\^@\^_"`
    test_basic_token_output(t, &str, {
        {.STRING_LIT, `"\^@\^_"`, 1},
    })
}

@(test)
test_tokenize_digit_string :: proc(t: ^testing.T) {
    str := `"\000\255"`
    test_basic_token_output(t, &str, {
        {.STRING_LIT, `"\000\255"`, 1},
    })
}

@(test)
test_tokenize_comment :: proc(t: ^testing.T) {
    str := `(* comment *)`
    test_basic_token_output(t, &str, {
        {.COMMENT, `(* comment *)`, 1},
    })
}

@(test)
test_tokenize_comments_and_nums :: proc(t: ^testing.T) {
    str := `123 (*25*)0 (**) 34(* 8 *) 9`
    test_basic_token_output(t, &str, {
        {.ALPHANUMERIC, `123`,      1},
        {.COMMENT,      `(*25*)`,   1},
        {.ALPHANUMERIC, `0`,        1},
        {.COMMENT,      `(**)`,     1},
        {.ALPHANUMERIC, `34`,       1},
        {.COMMENT,      `(* 8 *)`,  1},
        {.ALPHANUMERIC, `9`,        1},
    })
}

@(test)
test_tokenize_nested_comments :: proc(t: ^testing.T) {
    str := `(* comment (* layer 2 *) *)`
    test_basic_token_output(t, &str, {
        {.COMMENT, `(* comment (* layer 2 *) *)`, 1},
    })
}

@(test)
test_tokenize_squashed_comments :: proc(t: ^testing.T) {
    str := `(*(**)(**)*)(*)*)`
    test_basic_token_output(t, &str, {
        {.COMMENT, `(*(**)(**)*)`, 1},
        {.COMMENT, `(*)*)`, 1},
    })
}

@(test)
test_tokenize_comments_and_strings :: proc(t: ^testing.T) {
    str := `(*"*) (* "abc" "123 *) " lmnop )* "`
    test_basic_token_output(t, &str, {
        {.COMMENT,    `(*"*)`,            1},
        {.COMMENT,    `(* "abc" "123 *)`, 1},
        {.STRING_LIT, `" lmnop )* "`,     1},
    })
}



@(test)
test_tokenize_full_keyword :: proc(t: ^testing.T) {
    str := "{"
    test_full_token_output(t, &str, {
        {.RESERVED_KEYWORD, "{", 1},
    })
}



test_basic_token_output :: proc(t: ^testing.T, input: ^string, expected: []Basic_Token) {
    testing.set_fail_timeout(t, 3 * time.Second)

    basic_tokens := basic_tokenize(input)
    defer {
        for token in basic_tokens {
            delete(token.text)
        }
        delete(basic_tokens)
    }

    testing.expect_value(t, len(basic_tokens), len(expected))
    
    for basic_token, i in basic_tokens {
        expected_token := expected[i]
        testing.expect_value(t, basic_token.type, expected_token.type)
        testing.expect_value(t, basic_token.text, expected_token.text)
        testing.expect_value(t, basic_token.line, expected_token.line)
    }
}

test_full_token_output :: proc(t: ^testing.T, input: ^string, expected: []Full_Token) {
    testing.set_fail_timeout(t, 3 * time.Second)

    basic_tokens := basic_tokenize(input)
    defer {
        for token in basic_tokens {
            delete(token.text)
        }
        delete(basic_tokens)
    }

    full_tokens := full_token_pass(basic_tokens)
    defer {
        for token in full_tokens {
            delete(token.text)
        }
        delete(full_tokens)
    }

    testing.expect_value(t, len(full_tokens), len(expected))
    
    for full_token, i in full_tokens {
        expected_token := expected[i]
        testing.expect_value(t, full_token.type, expected_token.type)
        testing.expect_value(t, full_token.text, expected_token.text)
        testing.expect_value(t, full_token.line, expected_token.line)
    }
}

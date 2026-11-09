package parser

import "core:fmt"
import "../lexer"
import "../ast"
import str "core:strings"


parse_pattern :: proc(parser: ^Parser) -> (out: ^ast.Pattern, out_err: ^ParseErr) {
    return parse_infix_pattern(parser)
    // <alpha_ident> (`:` TYPE)* (as PATTERN)?
    // INFIX_PATTERN (`:` TYPE)*
}

parse_infix_pattern :: proc(parser: ^Parser) -> (out: ^ast.Pattern, out_err: ^ParseErr) {
    return parse_cted_pattern(parser)
    // CONSTRUCTED_PATTERN (<sym_ident> CONSTRUCTED_PATTERN)*
}

parse_cted_pattern :: proc(parser: ^Parser) -> (out: ^ast.Pattern, out_err: ^ParseErr) {
    return parse_atomic_pattern(parser)
    // <alpha_ident> ATOMIC_PATTERN
    // ATOMIC_PATTERN
}

parse_atomic_pattern :: proc(parser: ^Parser) -> (out: ^ast.Pattern, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }
    
    // <alpha_ident>
    // <literal>
    // `(` LIST_CONTENTS_PATTERN? `)`
    // `[` LIST_CONTENTS_PATTERN? `]`
    // `{` PATTERN_FIELDS? `...`? `}`
    
    ident, err := parse_ident(parser, false)
    if err == nil {
        return ast.new_ident_pattern(ident.name, ident.base_node), nil
    }
    return nil, err;

    // TODO: add other cases
}
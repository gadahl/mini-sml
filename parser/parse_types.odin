package parser

import "core:fmt"
import "../lexer"
import "../ast"
import str "core:strings"


parse_type :: proc(parser: ^Parser) -> (out: ^ast.Type, out_err: ^ParseErr) {
    return parse_tuple_type(parser)
}

parse_tuple_type :: proc(parser: ^Parser) -> (out: ^ast.Type, out_err: ^ParseErr) {
    return parse_cted_type(parser)
}

parse_cted_type :: proc(parser: ^Parser) -> (out: ^ast.Type, out_err: ^ParseErr) {
    return parse_atomic_type(parser)
}

parse_atomic_type :: proc(parser: ^Parser) -> (out: ^ast.Type, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }
    
    // <literal> 
    // <alpha_ident>
    // `(` PAREN_CONTENTS? `)`
    // `[` LIST_CONTENTS? `]`
    // `{` RECORD_FIELDS? `}`
    // `#` <alpha_ident>
    // `let` DECLS `in` EXPR `end`

    ident, err := parse_ident(parser, false)
    if err == nil {
        return ast.new_ident_type(ident.name, ident.base_node), nil
    }
    return nil, err;

    // TODO: add other cases

    
}
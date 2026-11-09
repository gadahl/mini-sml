package parser

import "core:fmt"
import "../lexer"
import "../ast"
import str "core:strings"


parse_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    return parse_handled_expr(parser)
}

parse_handled_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    return parse_orelse_expr(parser)
}

parse_orelse_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    return parse_andalso_expr(parser)
}

parse_andalso_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    return parse_typed_expr(parser)
}

parse_typed_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    return parse_infix_expr(parser)
}

parse_infix_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    return parse_appl_expr(parser)
}

parse_appl_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    return parse_atomic_expr(parser)
}

parse_atomic_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }
    
    // <literal> 
    // <alpha_ident>
    // `(` PAREN_CONTENTS? `)`
    // `[` LIST_CONTENTS? `]`
    // `{` RECORD_FIELDS? `}`
    // `#` <alpha_ident>
    // `let` DECLS `in` EXPR `end`

    
    if ident, err := parse_ident(parser, false); err == nil {
        return ast.new_ident_expr(ident.name, ident.base_node), nil
    }
    if lit, node, err := parse_literal(parser); err == nil {
        return ast.new_literal_expr(lit, node^), nil
    }
    // TODO: add other cases
    return nil, new_temp_err(fmt.tprintf("Expected atomic expression, but could not parse any"));

}
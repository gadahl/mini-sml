package parser

import "core:fmt"
import str "core:strings"
import "../lexer"
import "../ast"


parse_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    // HANDLED_EXPR
    // `raise` EXPR
    // `if` EXPR `then` EXPR `else` EXPR
    // `while` EXPR `do` EXPR
    // `case` EXPR `of` MATCH
    // `fn` MATCH
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
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }
    
    // INFIX_EXPR (`:` TYPE)?

    infix, err := parse_infix_expr(parser)
    if err != nil {
        return nil, err
    }

    if err := parse_keyword(parser, ":"); err == nil {
        // needs to have a type, otherwise invalid
        
        ty, err := parse_type(parser)
        if err != nil {
            return nil, err
        }
        return ast.new_typed_expr(infix, ty), nil
    }
    else {
        return infix, nil
    }
}

parse_infix_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    // APPL_EXPR (<sym_ident> APPL_EXPR)*
    return parse_appl_expr(parser)
}

parse_appl_expr :: proc(parser: ^Parser) -> (out: ^ast.Expr, out_err: ^ParseErr) {
    // ATOMIC_EXPR+
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
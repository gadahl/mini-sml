package parser

import "core:fmt"
import str "core:strings"
import "../lexer"
import "../ast"


parse_decls :: proc(parser: ^Parser) -> (out: ^ast.Seq_Decl, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }
    
    // DECL (`;` DECL)*

    first, err := parse_decl(parser)
    if err != nil do return nil, err

    decl_list := make([dynamic]^ast.Decl)
    append(&decl_list, first)
    
    err = nil
    for {
        done := parse_keyword(parser, ";")
        if done != nil do break

        decl : ^ast.Decl
        decl, err = parse_decl(parser)
        if err != nil do break
        append(&decl_list, decl)
    }
    if err != nil {
        // TODO: delete stuff inside the list
        delete(decl_list)
        return nil, err
    }
    
    return ast.new_seq_decl(decl_list, first.base_node), nil
}

parse_decl :: proc(parser: ^Parser) -> (out: ^ast.Decl, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }

    // `val` VAL_BINDS
    // `fun` FUN_BINDS
    // `local` DECLS `in` DECLS `end`
    // `infix` INFIX_DETAILS
    // `infixr` INFIX_DETAILS
    // ε

    if err := parse_keyword(parser, "val"); err == nil {
        return parse_val_binds(parser)
    }
    else if err = parse_keyword(parser, "fun"); err == nil {
        // must parse: FUN_BINDS
    }
    else if err = parse_keyword(parser, "local"); err == nil {
        // must parse: DECLS `in` DECLS `end`
    }
    else if err = parse_keyword(parser, "infix"); err == nil {
        // must parse: INFIX_DETAILS
    }
    else if err = parse_keyword(parser, "infixr"); err == nil {
        // must parse: INFIX_DETAILS
    }
    else {
        return ast.new_empty_decl(ast.Node{ }), nil
    }
    return nil, new_temp_err("unimplemented decl")
}

parse_val_binds :: proc(parser: ^Parser) -> (out: ^ast.Decl, out_err: ^ParseErr) {
    return parse_val_bind(parser)
}

parse_val_bind :: proc(parser: ^Parser) -> (out: ^ast.Decl, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }
    
    is_rec := false
    if err := parse_keyword(parser, "rec"); err == nil {
        is_rec = true
    }

    pat, pat_err := parse_pattern(parser)
    if pat_err != nil {
        return nil, pat_err
    }

    if err := parse_keyword(parser, "="); err != nil {
        return nil, err
    }

    expr, expr_err := parse_expr(parser)
    if expr_err != nil {
        return nil, expr_err
    }

    return ast.new_val_decl(is_rec, pat, expr, pat.base_node), nil
}

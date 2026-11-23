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

    // NOTE: this doesnt let you put empty decls in the middle of the file if they don't end with ; 
    empty_err := peek_keyword(parser, ";")
    if empty_err == nil || !parser_has_next(parser) {
        return ast.new_empty_decl(ast.Node{ }), nil
    }

    if err := parse_keyword(parser, "val"); err == nil {
        return parse_val_binds(parser)
    }
    else if err = parse_keyword(parser, "fun"); err == nil {
        return parse_fun_binds(parser)
    }
    else if err = parse_keyword(parser, "local"); err == nil {
        // must parse: DECLS `in` DECLS `end`
        return nil, new_temp_err("unimplemented decl")
    }
    else if err = parse_keyword(parser, "infix"); err == nil {
        return parse_infix_details(parser, false)
    }
    else if err = parse_keyword(parser, "infixr"); err == nil {
        return parse_infix_details(parser, true)
    }
    return nil, new_temp_err("could not parse decl") 
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

parse_fun_binds :: proc(parser: ^Parser) -> (out: ^ast.Decl, out_err: ^ParseErr) {
    return parse_fun_bind(parser)
}

parse_fun_bind :: proc(parser: ^Parser) -> (out: ^ast.Decl, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }

    first_arm, first_err := parse_fun_arm(parser)
    if first_err != nil do return nil, first_err
    
    arms := make([dynamic]^ast.Fun_Arm)
    append(&arms, first_arm)

    for {
        if err := parse_keyword(parser, "|"); err != nil {
            break;
        }
        
        next_arm, arm_err := parse_fun_arm(parser)
        if arm_err != nil do return nil, arm_err
        
        append(&arms, next_arm)
    }

    num_args := len(first_arm.args) // must be the same for all arms
    for arm in arms {
        if len(arm.args) != num_args {
            return ast.new_bad_decl(ast.Node{}), nil // TODO: error handling
        }
    }
    
    return ast.new_fun_decl(arms, ast.Node{}), nil // TODO: replace ast.Node{}
}

parse_fun_arm :: proc(parser: ^Parser) -> (out: ^ast.Fun_Arm, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }
    
    // TODO: infix declarations, typed signatures?

    name, name_err := parse_ident(parser, false)
    if name_err != nil do return nil, name_err

    args := make([dynamic]^ast.Pattern)

    first_arg, arg_err := parse_atomic_pattern(parser)
    if arg_err != nil do return nil, arg_err
    append(&args, first_arg)

    for {
        if err := parse_keyword(parser, "="); err == nil {
            break;
        }

        next_arg, arg_err := parse_atomic_pattern(parser)
        if arg_err != nil do return nil, arg_err

        append(&args, next_arg)
    }

    expr, expr_err := parse_expr(parser)
    if expr_err != nil {
        return nil, expr_err
    }

    return ast.new_fun_arm(str.clone(name.name), args, expr), nil
}

parse_infix_details :: proc(parser: ^Parser, is_right_assoc: bool) -> (out: ^ast.Infix_Decl, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }

    // <literal>? <sym_ident>+
    
    snugness: int = 0 // default snugness of 0
    lit, node, err := parse_literal(parser)
    if err == nil {
        if num, valid := lit.(i32); valid {
            snugness = int(num)
        }
        else {
            return nil, new_temp_err("infix keyword must be followed by a positive number or operators")
        }
    }

    first_ident, ident_err := parse_ident(parser, true)
    if ident_err != nil {
        return nil, ident_err
    }

    names := make([dynamic]string)
    append(&names, str.clone(first_ident.name))

    for {
        ident, ident_err := parse_ident(parser, true)
        if ident_err != nil do break
        append(&names, str.clone(ident.name))
    }

    return ast.new_infix_decl(is_right_assoc, snugness, names, first_ident.base_node), nil
}

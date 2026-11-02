package parser

import "core:fmt"
import "../lexer"
import "../ast"
import str "core:strings"


Parser :: struct {
    tokens: []lexer.Token,
    curr_token: ^lexer.Token,
    i: int,
    markers: [dynamic]int,
}

parser_make :: proc(tokens: []lexer.Token) -> Parser {
    return Parser{
        tokens = tokens,
        curr_token = &tokens[0],
        i = 0,
        markers = make([dynamic]int),
    }
}
parser_delete :: proc(parser: ^Parser) { 
    delete(parser.markers)
}
parser_advance :: proc(parser: ^Parser) {
    parser.i += 1
    parser.curr_token = &parser.tokens[parser.i]
}
parser_has_next :: proc(parser: ^Parser) -> bool {
    return parser.i + 1 < len(parser.tokens)
}
parser_at_keyword :: proc(parser: ^Parser, s: string) -> bool {
    if parser.curr_token.type != .RESERVED_KEYWORD do return false
    return parser.curr_token.text == s
}
parser_mark :: proc(parser: ^Parser) {
    append(&parser.markers, parser.i)
}
parser_rewind :: proc(parser: ^Parser) {
    parser.i = pop(&parser.markers)
    parser.curr_token = &parser.tokens[parser.i]
}
parser_pop :: proc(parser: ^Parser) {
    pop(&parser.markers)
}


ParseErr :: struct {
    message: string,
}
new_temp_err :: proc(message: string) -> ^ParseErr {
    err := new(ParseErr, context.temp_allocator)
    err.message = message
    return err
}


parse_program :: proc(ts: []lexer.Token) -> (^ast.Seq_Decl, ^ParseErr) {

    free_all(context.temp_allocator)

    parser := parser_make(ts)
    defer parser_delete(&parser)

    result, temp_err := parse_decls(&parser)
    if temp_err != nil {
        err := new(ParseErr)
        err.message = str.clone(temp_err.message)
        return nil, err
    }

    if parser_has_next(&parser) {
        err := new(ParseErr)
        err.message = fmt.aprintf("Expected end of file, but got token %v", parser.curr_token)
        return nil, err
    }

    free_all(context.temp_allocator)

    return result, nil
}


parse_keyword :: proc(parser: ^Parser, keyword: string) -> (out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }

    if !parser_has_next(parser) {
        return new_temp_err(fmt.tprintf("Expected keyword `%s`, but reached end of file", keyword))
    }

    t := parser.curr_token
    parser_advance(parser)

    if t.type != lexer.Token_Type.RESERVED_KEYWORD {
        return new_temp_err(fmt.tprintf("Expected keyword `%s`, but got token of type %v", keyword, t.type))
    }

    if t.text != keyword {
        return new_temp_err(fmt.tprintf("Expected keyword `%s`, but got `%s`", keyword, t.text))
    }

    return nil
}


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
        // must parse: VAL_BINDS
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
    return nil, nil

}
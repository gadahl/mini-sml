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

parse_ident :: proc(parser: ^Parser, is_symbolic: bool) -> (out: ^ast.Name, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }

    if !parser_has_next(parser) {
        return nil, new_temp_err(fmt.tprintf("Expected identifier, but reached end of file"))
    }

    t := parser.curr_token
    parser_advance(parser)

    if (!is_symbolic && t.type == lexer.Token_Type.ALPHANUM_IDENT) || 
        (is_symbolic && t.type == lexer.Token_Type.SYMBOLIC_IDENT) {
        return ast.new_name(str.clone(t.text), ast.Node{ line=t.line, offset=0 }), nil
    }
    else {
        expected := is_symbolic ? "infix identifier" : "identifier"
        return nil, new_temp_err(fmt.tprintf("Expected %s, but got token of type %v", expected, t.type))
    }
}

parse_literal :: proc(parser: ^Parser) -> (out1: ast.Literal_Value, out2: ^ast.Node, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }

    if !parser_has_next(parser) {
        return nil, nil, new_temp_err(fmt.tprintf("Expected identifier, but reached end of file"))
    }

    t := parser.curr_token
    parser_advance(parser)

    val: ast.Literal_Value = nil

    if t.type == lexer.Token_Type.INTEGER_LIT {
        val = t.literal_value.(i32)
    }
    else if t.type == lexer.Token_Type.REAL_LIT {
        val = t.literal_value.(f32)
    }
    else if t.type == lexer.Token_Type.STRING_LIT {
        val = t.literal_value.(string)
    }
    
    if val != nil {
        node := new(ast.Node)
        node ^= ast.Node{ line=t.line, offset=0 }
        return val, node, nil
    }
    else {
        return nil, nil, new_temp_err(fmt.tprintf("Expected literal value, but got token of type %v", t.type))
    }
}

package parser

import "core:fmt"
import str "core:strings"
import "../lexer"
import "../ast"


parse_pattern :: proc(parser: ^Parser) -> (out: ^ast.Pattern, out_err: ^ParseErr) {
    parser_mark(parser)
    defer { if out_err == nil { parser_pop(parser) } else { parser_rewind(parser) } }
    
    // <alpha_ident> (`:` TYPE)? (as PATTERN)? 
    //                            ^ TODO LATER
    // INFIX_PATTERN (`:` TYPE)?

    infix, err := parse_infix_pattern(parser)
    if err != nil {
        return nil, err
    }

    if err := parse_keyword(parser, ":"); err == nil {
        // needs to have a type, otherwise invalid
        
        ty, err := parse_type(parser)
        if err != nil {
            return nil, err
        }
        return ast.new_typed_pattern(infix, ty), nil
    }
    else {
        return infix, nil
    }
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
    
    
    if ident, err := parse_ident(parser, false); err == nil {
        return ast.new_ident_pattern(ident.name, ident.base_node), nil
    }
    if lit, node, err := parse_literal(parser); err == nil {
        return ast.new_literal_pattern(lit, node^), nil
        // NOTE: we need to avoid having just a literal pattern on the lhs of an assignment
    }
    // TODO: add other cases
    return nil, new_temp_err(fmt.tprintf("Expected atomic pattern, but could not parse any"));

}
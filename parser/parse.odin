package parser

import "core:fmt"
import "base:runtime"
import "../lexer"
import "../ast"
import str "core:strings"


StackItem :: struct { 
    nt: Nonterminal, 
    token_start: int,
    opt: int, 
    progress: int,
}

Parser :: struct {
    tokens: []lexer.Token,
    curr_token: ^lexer.Token,
    i: int,
    stack: [dynamic]StackItem,
    root: ^ast.Type,
    frontier: [dynamic]ast.Node,
}

parser_make :: proc(tokens: []lexer.Token) -> Parser {
    stack := make([dynamic]StackItem)
    root := new(ast.Type);
    frontier := make([dynamic]ast.Node)
    return Parser{
        tokens = tokens,
        curr_token = nil,
        i = -1,
        stack = stack,
        root = root, 
        frontier = frontier,
    }
}
parser_delete :: proc(parser: ^Parser) { 
    delete(parser.stack)
    delete(parser.frontier) 
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
    return str.compare(parser.curr_token.text, s) == 0
}


build_tree :: proc(ts: []lexer.Token) {
    parser := parser_make(ts)
    defer parser_delete(&parser)

    //append(&parser.stack, StackItem{.DECLS, 0, 0, 0})
    //append(&parser.frontier, parser.root.base_node)
    append(&parser.stack, StackItem{.TYPE, 0, 0, 0})

    do_advance := true
    for {
        if do_advance {
            if parser_has_next(&parser){
                parser_advance(&parser)
            }
            else do break
        }
        do_advance = false
        
        terminal := terminal_from_token(parser.curr_token)
        if terminal == .EPSILON do continue

        // terminal != epsilon at this point
        if len(parser.stack) == 0 do break 

        do_advance = parse_step(&parser, terminal)
    }

    
    end_terminal := terminal_from_token(parser.curr_token)

    // if there are more terminals remaining, panic
    // ("unbalanced close paren" type of error)
    if end_terminal != .EOF {
            panic(fmt.tprintf("nonterminal stack is empty so program should end, but got terminal %v", 
                end_terminal))
    }

    // if the stack hasn't emptied, panic
    // ("unbalanced open paren" type of error)
    if len(parser.stack) != 0 {
        strs := make([dynamic]string, context.temp_allocator)
        for item in parser.stack {
            append(&strs, fmt.tprintf("%v[%d/%d] ", item.nt, item.progress, len(rule_table[item.nt][item.opt].seq)))
        }
        panic(fmt.tprintf("program ended but nonterminal stack still contains: %#v", strs))
    }
}


/* 
    Take one parsing step: either exit a production, enter a production, or consume a terminal.

    Assumes `parser.stack` is not empty. 

    Returns whether to advance to the next terminal.
*/
parse_step :: proc(parser: ^Parser, parsed_terminal: Terminal) -> bool {

    curr_item := get_last_ptr(parser.stack[:])
    curr_prod := rule_table[curr_item.nt][curr_item.opt]

    if curr_item.progress >= len(curr_prod.seq) {
        // *** EXIT STEP ***
        exit_production(parser)
        return false
    }
    else {
        curr_symbol := curr_prod.seq[curr_item.progress]

        switch sym in curr_symbol {

        case Nonterminal:
            // *** ENTER STEP***
            enter_production(parser, sym, parsed_terminal)
            return false

        case Terminal: 
            // make sure that the terminal we find in the production is the same as the one we were given
            if sym != parsed_terminal {
                panic(fmt.tprintf("in derivation of `%v`, predicted `%s`, found `%s`", 
                        curr_item.nt, terminal_strings[sym], terminal_strings[parsed_terminal]))
            }

            // *** CONSUME STEP ***

            // put this onto the node stack if it has important information
            if sym == .alpha_ident_ || sym == .sym_ident_ {
                name_node := new(ast.Name)
                name_node^ = ast.Name {
                    //offset=parser.curr_token.,
                    line=parser.curr_token.line,
                    name=parser.curr_token.text,
                    is_symbolic=(sym==.sym_ident_),
                }
                ast.connect(&name_node.base_node, name_node)
                append(&parser.frontier, name_node)
            }

            curr_item.progress += 1
            print_stack(parser.stack[:])
                
            return true

        case: panic("bad symbol value, neither a terminal nor a nonterminal")
        }
    }
}


// gets a pointer to the last element of the slice
get_last_ptr :: proc(arr: []$T) -> ^T {
    return &arr[len(arr) - 1]
}


enter_production :: proc(parser: ^Parser, nt_to_enter: Nonterminal, curr_terminal: Terminal) {
    prod_options := rule_table[nt_to_enter]
    chosen_prod : Maybe(Production) = nil
    chosen_i := -1

    for prod_option, i in prod_options {
        if curr_terminal in prod_option.start {
            chosen_prod = prod_option
            chosen_i = i
            break
        }
    }

    if chosen_prod, ok := chosen_prod.?; ok {
        append(&parser.stack, StackItem{nt_to_enter, parser.i, chosen_i, 0})
    }
    else {
        panic(fmt.tprintf("can't start `%s` with `%s`", 
                nt_to_enter, terminal_strings[curr_terminal]))
    }
}


exit_production :: proc(parser: ^Parser) {
    popped := pop(&parser.stack)
    print_popped(parser, popped) // TODO: remove me

    if (len(parser.stack) == 0) {
        // the popped node is the full tree
        fmt.println("FRONTIER:")
        ast.print_tree(parser.frontier[0])
    }
    else {
        parent_item := get_last_ptr(parser.stack[:])

        handle_pop(parser, popped, parent_item^)

        parent_item.progress += 1
    }

}


terminal_from_token :: proc(token: ^lexer.Token) -> Terminal {
    switch token.type {
    case .TYPE_VAR: panic("got type variable token, but there is no type variable in grammar!")
    case .ALPHANUM_IDENT: return .alpha_ident_
    case .SYMBOLIC_IDENT: return .sym_ident_
    case .INTEGER_LIT: return .literal_
    case .STRING_LIT: return .literal_
    case .REAL_LIT: return .literal_
    case .COMMENT: return .EPSILON
    case .WILDCARD: panic("got wildcard token, but there is no wildcard in grammar!")
    case .EOF: return .EOF
    case .RESERVED_KEYWORD: 
        for t in Terminal {
            if str.compare(token.text, terminal_strings[t]) == 0 {
                return t
            }
        } 
        panic(fmt.tprintf("couldn't match keyword token `%s` with terminal!", token.text))
    }
    panic("didn't return from switch")
}


print_stack :: proc(stack: []StackItem) {
    for item in stack {
        fmt.printf("%v[%d/%d] ", item.nt, item.progress, len(rule_table[item.nt][item.opt].seq))
    }
    fmt.println()
}

print_popped :: proc(parser: ^Parser, popped: StackItem) {
    fmt.printf("%28s", fmt.tprintf("%v[%d/%d] ", popped.nt, popped.progress, len(rule_table[popped.nt][popped.opt].seq)))

    for i in popped.token_start..<parser.i {
        fmt.printf("%s ", terminal_strings[terminal_from_token(&parser.tokens[i])])
    }

    fmt.println()
}

append_empty_list :: proc(parser: ^Parser) {
    empty_list := new(ast.Node_List)
    empty_list.elements = make([dynamic]ast.Node)
    empty_list.node_variant = empty_list
    append(&parser.frontier, empty_list)
}


get_frontier_subtype :: proc(parser: ^Parser, $T: typeid, loc: runtime.Source_Code_Location = #caller_location) -> ^T {
    node := pop(&parser.frontier)
    node_list, ok1 := node.node_variant.(^T) 
    if !ok1 do panic(fmt.tprintf("expected %v, but found:\n%#v", typeid_of(T), node.node_variant), loc=loc)
    return node_list
}


handle_pop :: proc(parser: ^Parser, popped: StackItem, parent: StackItem) {
    popped_seq := rule_table[popped.nt][popped.opt].seq
    parent_seq := rule_table[parent.nt][parent.opt].seq
    
    if len(popped_seq) == 0 {
        append_empty_list(parser)
        return
    }

    popped_0 := popped_seq[0]

    switch popped.nt {
        case .DECLS:
        case .DECLS_1:
        case .DECL:
        case .VAL_BINDS:
        case .VAL_BINDS_1:
        case .VAL_BIND:
        case .FUN_BINDS:
        case .FUN_BINDS_1:
        case .FUN_BIND:
        case .FUN_BIND_1:
        case .FUN_ARM:
        case .FUN_ARM_1:
        case .FUN_ARGS:
        case .OPT_TYPING:
        case .INFIX_DETAILS:
        case .INFIX_IDENTS:
        case .PATTERN:
        case .PATTERN_1:
        case .TYPE_SPECS:
        case .INFIX_PATTERN:
        case .INFIX_PATTERN_1:
        case .CONSTRUCTED_PATTERN:
        case .CONSTRUCTED_PATTERN_1:
        case .ATOMIC_PATTERN:
        case .NON_ALPHA_ATOMIC_PATTERN:
        case .OPT_ELLIPSIS:
        case .PATTERN_FIELDS:
        case .PATTERN_FIELDS_1:
        case .PATTERN_FIELD:
        case .PATTERN_FIELD_1:
        case .OPT_AS_PATTERN:
        case .LIST_CONTENTS_PATTERN:
        case .LIST_CONTENTS_PATTERN_1:
        case .EXPR:
        case .HANDLED_EXPR:
        case .HANDLED_EXPR_1:
        case .ORELSE_EXPR:
        case .ORELSE_EXPR_1:
        case .ANDALSO_EXPR:
        case .ANDALSO_EXPR_1:
        case .TYPED_EXPR:
        case .INFIX_EXPR:
        case .INFIX_EXPR_1:
        case .APPL_EXPR:
        case .ATOMIC_EXPRS:

        case .ATOMIC_EXPR:
            if popped_0 == .literal_ {
                // literal
                literal := new(ast.Literal_Expr)
                literal^ = ast.Literal_Expr{
                    offset = 0,
                    line = parser.curr_token.line,
                }
                literal.base_expr.expr_variant = literal
                literal.base_node.node_variant = &literal.base_expr

                switch val in parser.curr_token.literal_value {
                    case i32: literal.value = val
                    case f32: literal.value = val
                    case string: literal.value = str.clone(val)
                    case lexer.Undefined, lexer.No_Value: 
                        panic(fmt.tprintf("expected value from literal, but got %v!", val))
                }
                append(&parser.frontier, literal.base_node)
            }
            else if popped_0 == .alpha_ident_ {
                // alpha ident expr
            }
            else if popped_0 == .hash {
                // label
            }
        case .RECORD_FIELDS:

        case .RECORD_FIELDS_1:
        case .RECORD_FIELD:
        case .LIST_CONTENTS:
        case .LIST_CONTENTS_1:
        case .PAREN_CONTENTS:
        case .PAREN_CONTENTS_1:
        case .EXPR_SEQ_1:
        case .MATCH:
        case .MATCH_1:
        case .MATCH_RULE:

        case .TYPE: // --.

        case .FN_TYPE: // TupleList, TypeA/EmptyList -- FuncType/TupleType.
            // get the top 2 stack items, and join them if the 2nd isn't empty
            codomain_node := pop(&parser.frontier)
            codomain, codomain_exists := codomain_node.node_variant.(^ast.Type); 
            // if !codomain_exists, it means that codomain_node was an empty node_list

            tuple_elements := get_frontier_subtype(parser, ast.Node_List)
            domain: ^ast.Type

            if (len(tuple_elements.elements) == 1) {
                // unpack the singleton tuple
                node := tuple_elements.elements[0]
                ty, ok := node.node_variant.(^ast.Type)
                //if !ok do panic(fmt.tprintf("expected Type, but found %#v", node.node_variant))
                domain = ty
            }
            else {   
                tuple_node := new(ast.Tuple_Type)
                tuple_node^ = ast.Tuple_Type {
                    base_node=tuple_elements.base_node,
                    components=make([dynamic]ast.Type),
                }
                ast.connect(&tuple_node.base_type, tuple_node)
                for node in tuple_elements.elements {
                    ty, ok := node.node_variant.(^ast.Type)
                    if !ok do panic(fmt.tprintf("expected Type, but found %#v", node.node_variant))
                    append(&tuple_node.components, ty^)
                }
                delete(tuple_elements.elements)
                //free(tuple_elements)
                domain = tuple_node
            }
            
            if (codomain_exists) {
                // join the top two stack items into a func type
                func_type := new(ast.Func_Type)
                func_type^ = {domain=domain, codomain=codomain}
                ast.connect(&func_type.base_type, func_type)
    
                append(&parser.frontier, func_type.base_node)
            }
            else {
                append(&parser.frontier, domain.base_node)
            }

        case .FN_TYPE_1: // --.

        case .TUPLE_TYPE: // Type, TupleList -- TupleList.
                tuple_elements := get_frontier_subtype(parser, ast.Node_List)
                type := get_frontier_subtype(parser, ast.Type)
                
                inject_at(&tuple_elements.elements, 0, type)
                append(&parser.frontier, tuple_elements)

        case .TUPLE_TYPE_1: // `*`, TupleList -- TupleList.
                tuple_elements := get_frontier_subtype(parser, ast.Node_List)
                star := get_frontier_subtype(parser, ast.Name) // get the star out of here
                append(&parser.frontier, tuple_elements.base_node)

        case .CONSTRUCTED_TYPE: // Name/TypeA, CtedList/EmptyList -- CtedType/Ident/TypeA.
            cted_list := get_frontier_subtype(parser, ast.Node_List)
            type_node: ^ast.Type

            if popped_0 == .alpha_ident_ {
                name_node := get_frontier_subtype(parser, ast.Name)
                ident_node := new(ast.Ident_Type)
                ident_node^ = ast.Ident_Type {
                    name=str.clone(name_node.name),
                    base_node=name_node.base_node,
                }
                ast.connect(&ident_node.base_type, ident_node)
                type_node = &ident_node.base_type
            }
            else {
                type_node = get_frontier_subtype(parser, ast.Type)
            }

            if len(cted_list.elements) == 0 {
                append(&parser.frontier, type_node)
                break;
            }

            cted_node := new(ast.Constructed_Type)
            cted_node^ = ast.Constructed_Type {
                base_node=cted_list.base_node,
                args=make([dynamic]ast.Type),
            }
            ast.connect(&cted_node.base_type, cted_node)
            append(&cted_node.args, type_node^)
            for node in cted_list.elements {
                ty, ok := node.node_variant.(^ast.Type)
                if !ok do panic(fmt.tprintf("expected Type, but found %#v", node.node_variant))
                append(&cted_node.args, ty^)
                //free(ty)
            }
            //delete(cted_list.elements)
            //free(cted_elements)
            append(&parser.frontier, cted_node)
                
        case .AFTER_ALPHA_ATOMIC_TYPE: // --.

        case .CONSTRUCTED_TYPE_1: // NewList, Name, OldList -- OldList.
            // CONSTRUCTED_TYPE_1
            old_nodes := get_frontier_subtype(parser, ast.Node_List)

            // alpha_ident_
            // prepend this alpha ident to the old list
            name_node := get_frontier_subtype(parser, ast.Name)
            if name_node.is_symbolic do panic(fmt.tprintf("expected alpha-id, but found `%s`", name_node.name))
            
            ident := new(ast.Ident_Type)
            ident^ = ast.Ident_Type {
                base_node=name_node.base_node,
                name=name_node.name,
            }
            ast.connect(&ident.base_type, ident)
            inject_at(&old_nodes.elements, 0, ident)

            // NON_ALPHA_ATOMIC_TYPES
            // prepend this list to the old list
            new_nodes := get_frontier_subtype(parser, ast.Node_List)
            #reverse for n in new_nodes.elements {
                inject_at(&old_nodes.elements, 0, n)
            }

            // append old node list to the frontier again
            append(&parser.frontier, old_nodes.base_node)

        case .NON_ALPHA_ATOMIC_TYPE: // FieldList/ParenType -- Record/ParenType.
            if popped_0 == .lcur {
                //.lcur, .TYPE_FIELDS, .rcur
                // turn the node_list into a record_type
                node_list := get_frontier_subtype(parser, ast.Node_List)

                record := new(ast.Record_Type)
                record^ = ast.Record_Type {
                    base_node=node_list.base_node,
                    fields=make([dynamic]ast.Type_Field),
                }
                ast.connect(&record.base_type, record)
                for node in node_list.elements {
                    field, ok := node.node_variant.(^ast.Type_Field)
                    if !ok do panic(fmt.tprintf("expected Type_Field, but found %#v", node.node_variant))
                    append(&record.fields, field^)
                    free(field)
                }
            }
            else {
                //.lpar, .TYPE, .rpar
                // the type just bubbles up
            }

        case .NON_ALPHA_ATOMIC_TYPES: // Type, TypeList -- TypeList.
            // NON_ALPHA_ATOMIC_TYPES
            node_list := get_frontier_subtype(parser, ast.Node_List)

            // NON_ALPHA_ATOMIC_TYPE
            // prepend this to the existing list
            ty := get_frontier_subtype(parser, ast.Type)
            inject_at(&node_list.elements, 0, ty)
            
            // append old node list to the frontier again
            append(&parser.frontier, node_list.base_node)

        case .TYPE_FIELDS: // Field, FieldList -- FieldList.
            // TYPE_FIELDS_1
            node_list := get_frontier_subtype(parser, ast.Node_List)

            // TYPE_FIELD
            // prepend this to the existing list
            field := get_frontier_subtype(parser, ast.Type_Field)
            inject_at(&node_list.elements, 0, field)
            
            // append old node list to the frontier again
            append(&parser.frontier, node_list)

        case .TYPE_FIELDS_1: // --.

        case .TYPE_FIELD: // Name, Type -- Field.
            // .TYPE
            type_node := get_frontier_subtype(parser, ast.Type)

            // .NAME
            name_node := get_frontier_subtype(parser, ast.Name)
            if name_node.is_symbolic do panic(fmt.tprintf("expected alpha-id, but found `%s`", name_node.name))

            field := new(ast.Type_Field)
            field^ = ast.Type_Field {
                base_node=name_node.base_node,
                label    =name_node.name,
                type     =type_node,
            }
            ast.connect(&field.base_node, field)
            append(&parser.frontier, field)
    }
}
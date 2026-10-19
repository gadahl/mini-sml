package tree_builder

import "core:fmt"
import "../lexer"
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
}

parser_make :: proc(tokens: []lexer.Token) -> Parser {
    stack := make([dynamic]StackItem)
    return Parser{
        tokens = tokens,
        curr_token = nil,
        i = -1,
        stack = stack,
    }
}
parser_delete :: proc(parser: ^Parser) { 
    delete(parser.stack) 
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

    append(&parser.stack, StackItem{.DECLS, 0, 0, 0})

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
    // ("unbalanced closed paren" type of error)
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
        exit_production(parser)
        return false
    }
    else {
        curr_symbol := curr_prod.seq[curr_item.progress]

        switch sym in curr_symbol {

        case Nonterminal:
            enter_production(parser, sym, parsed_terminal)
            return false

        case Terminal: 
            // make sure that the terminal we find in the production is the same as the one we were given
            if sym == parsed_terminal {
                curr_item.progress += 1
            }
            else {
                panic(fmt.tprintf("in derivation of `%v`, predicted `%s`, found `%s`", 
                        curr_item.nt, terminal_strings[sym], terminal_strings[parsed_terminal]))
            }
            return true

        }
    }

    // debug
    //print_stack(parser.stack[:])
    return false
}


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
        
        // TODO: set up new node...

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
    }
    else {
        parent_item := get_last_ptr(parser.stack[:])
        parent_item.progress += 1

        // combine popped node with parent
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
    fmt.printf("%24s", fmt.tprintf("%v[%d/%d] ", popped.nt, popped.progress, len(rule_table[popped.nt][popped.opt].seq)))

    for i in popped.token_start..<parser.i {
        fmt.printf("%s ", terminal_strings[terminal_from_token(&parser.tokens[i])])
    }

    fmt.println()
}

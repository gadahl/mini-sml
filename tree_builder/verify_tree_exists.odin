package tree_builder

import "core:fmt"
import "../lexer"
import str "core:strings"


StackItem :: struct { nt: Nonterminal, opt: int, progress: int }

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

    append(&parser.stack, StackItem{.DECLS, 0, 0})

    for parser_has_next(&parser) {
        parser_advance(&parser)
        
        terminal := terminal_from_token(parser.curr_token)
        if terminal == .EPSILON do continue

        use_terminal(&parser, terminal)
    }

    if len(parser.stack) != 0 {
        strs := make([dynamic]string, context.temp_allocator)
        for item in parser.stack {
            append(&strs, fmt.tprintf("%v[%d/%d] ", item.nt, item.progress, len(rule_table[item.nt][item.opt].seq)))
        }
        panic(fmt.tprintf("program ended but nonterminal stack still contains: %#v", strs))
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

// consumes one token 
use_terminal :: proc(parser: ^Parser, terminal: Terminal) {
    
    if check_stack_empty(parser, terminal) do return
    production := rule_table[get_stack_top(parser).nt][get_stack_top(parser).opt]

    for get_stack_top(parser).progress >= len(production.seq) {
        is_stack_empty := finish_stack_item(parser, &production, terminal)
        if is_stack_empty do return
    }
    sym := production.seq[get_stack_top(parser).progress]
    
    // keep expanding nonterminals until one starts with a terminal
    nt, sym_is_nt := sym.(Nonterminal)
    for sym_is_nt {
        prods := rule_table[nt]
        flag := false
        for prod, i in prods {
            if terminal in prod.start {
                // use this production!
                append(&parser.stack, StackItem{nt, i, 0})
                
                if check_stack_empty(parser, terminal) do return
                production = prod

                for get_stack_top(parser).progress >= len(production.seq) {
                    is_stack_empty := finish_stack_item(parser, &production, terminal)
                    if is_stack_empty do return
                }
                sym = production.seq[get_stack_top(parser).progress]
                
                flag = true
                break
            }
        }
        if !flag {
            panic(fmt.tprintf("can't start `%s` with `%s`", 
                    nt, terminal_strings[terminal]))
        }
        nt, sym_is_nt = sym.(Nonterminal)
    }

    // make sure that the terminal we find in the production is the same as the one we were given
    switch sym in sym {
    case Terminal:
        if sym == terminal {
            get_stack_top(parser).progress += 1
        }
        else {
            panic(fmt.tprintf("predicted `%s`, found `%s`", 
                    terminal_strings[sym], terminal_strings[terminal]))
        }
    case Nonterminal:
        panic(fmt.tprintf("impossible non-terminal `%s`", sym))
    }

    // debug
    print_stack(parser.stack[:])
}

get_stack_top :: proc(parser: ^Parser) -> ^StackItem {
    return &parser.stack[len(parser.stack) - 1]
}


// returns whether the stack is empty, may panic
check_stack_empty :: proc(parser: ^Parser, terminal: Terminal) -> bool {
    if len(parser.stack) == 0 {
        if terminal == .EOF {
            return true
        }
        else {
            panic(fmt.tprintf("nonterminal stack is empty so program should end, but got terminal %v", 
                    terminal))
        }
    }
    return false
}


// returns whether the stack is now empty
finish_stack_item :: proc(parser: ^Parser, production: ^Production, terminal: Terminal) -> bool {
    popped := pop(&parser.stack)

    if check_stack_empty(parser, terminal) do return true

    top_item := get_stack_top(parser)
    top_item.progress += 1
    production^ = rule_table[top_item.nt][top_item.opt]

    return false
}


print_stack :: proc(stack: []StackItem) {
    for item in stack {
        fmt.printf("%v[%d/%d] ", item.nt, item.progress, len(rule_table[item.nt][item.opt].seq))
    }
    fmt.println()
}
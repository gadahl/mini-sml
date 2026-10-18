package compiler
import "core:fmt"

Nonterminal :: enum {
    DECLS, DECLS_1, DECL, VAL_BINDS, VAL_BINDS_1, VAL_BIND,
    FUN_BINDS, FUN_BINDS_1, FUN_BIND, FUN_BIND_1, FUN_ARM, FUN_ARM_1, FUN_ARGS, 
    OPT_TYPING, INFIX_DETAILS, INFIX_IDENTS,
    
    PATTERN, PATTERN_1, TYPE_SPECS, INFIX_PATTERN, INFIX_PATTERN_1, 
    CONSTRUCTED_PATTERN, CONSTRUCTED_PATTERN_1, ATOMIC_PATTERN, NON_ALPHA_ATOMIC_PATTERN, 
    OPT_ELLIPSIS, PATTERN_FIELDS, PATTERN_FIELDS_1, PATTERN_FIELD, PATTERN_FIELD_1, OPT_AS_PATTERN, 
    LIST_CONTENTS_PATTERN, LIST_CONTENTS_PATTERN_1,

    EXPR, HANDLED_EXPR, HANDLED_EXPR_1, ORELSE_EXPR, ORELSE_EXPR_1, 
    ANDALSO_EXPR, ANDALSO_EXPR_1, TYPED_EXPR,
    INFIX_EXPR, INFIX_EXPR_1, APPL_EXPR, ATOMIC_EXPRS, ATOMIC_EXPR, 
    RECORD_FIELDS, RECORD_FIELDS_1, RECORD_FIELD, LIST_CONTENTS, LIST_CONTENTS_1, 
    PAREN_CONTENTS, PAREN_CONTENTS_1, EXPR_SEQ_1, MATCH, MATCH_1, MATCH_RULE,

    TYPE, TYPE_1, TUPLE_TYPE, TUPLE_TYPE_1, CONSTRUCTED_TYPE, CONSTRUCTED_TYPE_1, 
    ATOMIC_TYPE, NON_ALPHA_ATOMIC_TYPE, NON_ALPHA_ATOMIC_TYPES,
    TYPE_FIELDS, TYPE_FIELDS_1, TYPE_FIELD,
}

Terminal :: enum {
    lpar, rpar, lsqr, rsqr, lcur, rcur,
    pipe, colon, equal, semi, comma, hash,
    ellipsis, maps_to, fn_type,

    _rec, _val, _fun, _and, _local, _let, _in, _end, _infix, _infixr,
    _andalso, _orelse, _handle, _raise, _if, _then, _else,
    _while, _do, _case, _of, _fn, _as,

    alpha_ident_, sym_ident_, literal_,

    EOF, EPSILON
}

terminal_strings: [Terminal]string = {
    .lpar="(", .rpar=")", .lsqr="[", .rsqr="]", .lcur="{", .rcur="}",
    .pipe="|", .colon=":", .equal="=", .semi=";", .comma=",", .hash="#",
    .ellipsis="...", .maps_to="=>", .fn_type="->",

    ._rec="rec", ._val="val", ._fun="fun", ._and="and", ._local="local", 
    ._let="let", ._in="in", ._end="end", ._infix="infix", ._infixr="infixr",
    ._andalso="andalso", ._orelse="orelse", ._handle="handle", ._raise="raise", 
    ._if="if", ._then="then", ._else="else",
    ._while="while", ._do="do", ._case="case", ._of="of", ._fn="fn", ._as="as",

    .alpha_ident_="<alpha_ident>", .sym_ident_="<sym_ident>", .literal_="<literal>",

    .EOF="<eof>", .EPSILON="<epsilon>"
}

Symbol :: union { Terminal, Nonterminal }

Production :: struct {
    seq: []Symbol,
    start: ^map[Terminal]struct{},
}

rule_table: map[Nonterminal]([]Production)
first_table: map[Nonterminal](^map[Terminal]struct{})
follow_table: map[Nonterminal](^map[Terminal]struct{})

main :: proc() {
    rule_table = make(map[Nonterminal]([]Production))
    first_table = make(map[Nonterminal](^map[Terminal]struct{}))
    follow_table = make(map[Nonterminal](^map[Terminal]struct{}))
    
    populate_table()

    for nt in Nonterminal {
        if nt in rule_table && len(rule_table[nt]) > 0 {
            fmt.println(nt)
            for prod in rule_table[nt] {
                fmt.print("  ")
                if len(prod.seq) == 0 {
                    eps := []u8{0xEE}
                    fmt.print(string(eps))
                }
                for symbol in prod.seq {
                    switch sym in symbol {
                        case Terminal: 
                            fmt.print(terminal_strings[sym], " ", sep="")
                        case Nonterminal:
                            fmt.print(sym, " ", sep="")
                    }
                }
                fmt.println()
            }
            fmt.println()
        }
    }
    
    //fmt.println("\n-------< FIRST TABLE >-------")
    calc_first()
    //print_result(&first_table)

    //fmt.println("\n------< FOLLOW TABLE >-------")
    calc_follow()
    //print_result(&follow_table)

    fmt.println("\n-------< START TABLE >-------")
    calc_start()
    for nt in Nonterminal {
        if nt in rule_table && len(rule_table[nt]) > 0 {
            fmt.println(nt)
            for prod in rule_table[nt] {
                fmt.println("-", prod.seq)
                fmt.print("        ")
                for t in Terminal {
                    if t not_in prod.start do continue
                    fmt.print(terminal_strings[t], " ", sep="")
                }
                fmt.println()
            }
            fmt.println()
        }
    }
}

set_insert :: proc(set: ^map[Terminal]struct{}, key: Terminal, making_progress: ^bool) {
    _, _, existed := map_upsert(set, key, struct{}{})
    if making_progress != nil && !existed do making_progress^ = true
}

calc_first :: proc() {
    for nt in Nonterminal {
        ts := new(map[Terminal]struct{})
        map_insert(&first_table, nt, ts)
    }
    
    making_progress := true
    for making_progress {
        making_progress = false
        
        for nt, first_set in first_table {
            rule := rule_table[nt]
            if len(rule) == 0 do continue
            // fmt.println(nt)
            // fmt.println(first_set)

            for production in rule {

                //fmt.println("  -", production.seq)
                trailing := true

                seqloop: for symbol in production.seq {
                    switch sym in symbol {
                    case Terminal:
                        set_insert(first_set, sym, &making_progress)
                        trailing = false
                        break seqloop
                    case Nonterminal:
                        t_first := first_table[sym]
                        for tf, _ in t_first {
                            if tf != .EPSILON {
                                set_insert(first_set, tf, &making_progress)
                            }
                        }
                        if .EPSILON not_in t_first {
                            trailing = false
                            break seqloop
                        }
                    }
                }
                if trailing {
                    set_insert(first_set, .EPSILON, &making_progress)
                }
            }
            
            // fmt.println(first_set)
            // fmt.println()
        }
    }
}

calc_follow :: proc() {
    for nt in Nonterminal {
        ts := new(map[Terminal]struct{})
        map_insert(&follow_table, nt, ts)
    }

    making_progress := true
    set_insert(follow_table[.DECLS], .EOF, &making_progress)

    trailer := make(map[Terminal]struct{})
    defer delete(trailer)

    for making_progress {
        making_progress = false
        
        for nt, follow_set in follow_table {
            rule := rule_table[nt]
            if len(rule) == 0 do continue
            // fmt.println(nt)
            // fmt.println(follow_set)

            for production in rule {

                clear(&trailer)
                for trailing_terminal in follow_set {
                    set_insert(&trailer, trailing_terminal, nil)
                }

                //fmt.println("  -", production.seq)

                seqloop: for i in 0..<len(production.seq) {
                    symbol := production.seq[len(production.seq) - 1 - i]
                    switch sym in symbol {
                    case Terminal:
                        clear(&trailer)
                        set_insert(&trailer, sym, nil)

                    case Nonterminal:
                        sym_follow := follow_table[sym]
                        sym_first := first_table[sym]
                        
                        for trailing_terminal, _ in trailer {
                            set_insert(sym_follow, trailing_terminal, &making_progress)
                        }
                        
                        if .EPSILON not_in sym_first {
                            clear(&trailer)
                        }
                        
                        // add FIRST(sym) to trailer
                        for leading_terminal, _ in sym_first {
                            if leading_terminal != .EPSILON {
                                set_insert(&trailer, leading_terminal, nil)
                            }
                        }
                    }
                }
            }
        }
    }
}

calc_start :: proc() {
    for nt, prods in rule_table {
        for &prod in prods {
            prod.start = new(map[Terminal]struct{})

            // if EVERY symbol in `seq` contains \eps, then `FIRST(seq)` contains \eps
            can_be_empty := true
            seqloop: for symbol in prod.seq {
                switch sym in symbol {
                case Terminal: 
                    if sym != .EPSILON{
                        can_be_empty = false
                        break seqloop
                    }
                case Nonterminal:
                    if .EPSILON not_in first_table[sym] {
                        can_be_empty = false
                        break seqloop
                    }
                }
            }

            if can_be_empty {
                // START(A -> seq) = (FIRST(seq) - \eps) U FOLLOW(A)
                if len(prod.seq) > 0 {
                    first_sym := prod.seq[0]
                    if sym, ok := first_sym.(Nonterminal); ok {
                        for leading_terminal in first_table[sym] {
                            if leading_terminal != .EPSILON {
                                set_insert(prod.start, leading_terminal, nil)
                            }
                        }
                    }
                }
                
                for following_terminal in follow_table[nt] {
                    set_insert(prod.start, following_terminal, nil)
                }
            }
            else {
                // START(A -> seq) = FIRST(seq)
                first_sym := prod.seq[0]
                switch sym in first_sym {
                case Terminal:
                    set_insert(prod.start, sym, nil)
                case Nonterminal:
                    for leading_terminal in first_table[sym] {
                        set_insert(prod.start, leading_terminal, nil)
                    }
                }
            }
        }
    }
}

print_result :: proc(set: ^map[Nonterminal](^map[Terminal]struct{})) {
    for nt in Nonterminal {
        if nt in set && len(set[nt]) > 0 {
            fmt.println(nt, "->", set[nt])
        }
    }
}

insert_rule :: proc(table: ^map[Nonterminal]([]Production), nt: Nonterminal, rule: [][]Symbol) {
    new_rule := make([]Production, len(rule))
    
    for i in 0..<len(rule) {
        seq := rule[i]
        new_seq := make([]Symbol, len(seq))
    
        for j in 0..<len(seq) {
            new_seq[j] = seq[j]
        }

        new_rule[i] = Production{seq=new_seq}
    }
    
    map_insert(table, nt, new_rule)
}

populate_table :: proc() {
    // Declarations
    insert_rule(&rule_table, Nonterminal.DECLS, {
        {.DECL, .DECLS_1},
    })
    insert_rule(&rule_table, Nonterminal.DECLS_1, {
        {.comma, .DECL, .DECLS_1},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.DECL, {
        {._val, .VAL_BINDS}, 
        {._fun, .FUN_BINDS}, 
        {._local, .DECLS, ._in, .DECLS, ._end},
        {._infix, .INFIX_DETAILS},
        {._infixr, .INFIX_DETAILS},
    })
    insert_rule(&rule_table, Nonterminal.VAL_BINDS, {
        {.VAL_BIND, .VAL_BINDS_1},
    })
    insert_rule(&rule_table, Nonterminal.VAL_BINDS_1, {
        {._and, .VAL_BIND, .VAL_BINDS_1},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.VAL_BIND, {
        {._rec, .PATTERN, .equal, .EXPR},
        {.PATTERN, .equal, .EXPR},
    })
    insert_rule(&rule_table, Nonterminal.FUN_BINDS, {
        {.FUN_BIND, .FUN_BINDS_1},
    })
    insert_rule(&rule_table, Nonterminal.FUN_BINDS_1, {
        {._and, .FUN_BIND, .FUN_BINDS_1},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.FUN_BIND, {
        {.FUN_ARM, .FUN_BIND_1},
    })
    insert_rule(&rule_table, Nonterminal.FUN_BIND_1, {
        {.pipe, .FUN_ARM, .FUN_BIND_1},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.FUN_ARM, {
        {.alpha_ident_, .FUN_ARM_1}, 
        {.NON_ALPHA_ATOMIC_PATTERN, .sym_ident_, .ATOMIC_PATTERN, .OPT_TYPING, .equal, .EXPR},
    })
    insert_rule(&rule_table, Nonterminal.FUN_ARM_1, {
        {.FUN_ARGS, .OPT_TYPING, .equal, .EXPR},  
        {.sym_ident_, .ATOMIC_PATTERN, .OPT_TYPING, .equal, .EXPR},
    })
    insert_rule(&rule_table, Nonterminal.FUN_ARGS, {
        {.ATOMIC_PATTERN, .FUN_ARGS},
        {},
    })
    insert_rule(&rule_table, Nonterminal.OPT_TYPING, {
        {.colon, .TYPE},
        {},
    })
    insert_rule(&rule_table, Nonterminal.INFIX_DETAILS, {
        {.literal_, .sym_ident_, .INFIX_IDENTS},
        {.sym_ident_, .INFIX_IDENTS},
    })
    insert_rule(&rule_table, Nonterminal.INFIX_IDENTS, {
        {.sym_ident_, .INFIX_IDENTS},
        {},
    })

    // Patterns
    insert_rule(&rule_table, Nonterminal.PATTERN, {
        // order matters
        {.alpha_ident_, .PATTERN_1},
        {.INFIX_PATTERN, .TYPE_SPECS},
    })
    insert_rule(&rule_table, Nonterminal.PATTERN_1, {
        {.ATOMIC_PATTERN, .INFIX_PATTERN_1, .TYPE_SPECS},
        {.TYPE_SPECS, ._as, .PATTERN},
        {.INFIX_PATTERN_1, .TYPE_SPECS},
    })

    insert_rule(&rule_table, Nonterminal.TYPE_SPECS, {
        {.colon, .TYPE, .TYPE_SPECS},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.INFIX_PATTERN, {
        {.CONSTRUCTED_PATTERN, .INFIX_PATTERN_1},
    })
    insert_rule(&rule_table, Nonterminal.INFIX_PATTERN_1, {
        {.sym_ident_, .CONSTRUCTED_PATTERN, .INFIX_PATTERN_1},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.CONSTRUCTED_PATTERN, {
        {.alpha_ident_, .CONSTRUCTED_PATTERN_1},
        {.NON_ALPHA_ATOMIC_PATTERN},
    })
    insert_rule(&rule_table, Nonterminal.CONSTRUCTED_PATTERN_1, {
        {.ATOMIC_PATTERN},
        {},
    })
    insert_rule(&rule_table, Nonterminal.ATOMIC_PATTERN, {
        {.alpha_ident_},
        {.NON_ALPHA_ATOMIC_PATTERN},
    })
    insert_rule(&rule_table, Nonterminal.NON_ALPHA_ATOMIC_PATTERN, {
        {.literal_},
        {.lpar, .LIST_CONTENTS_PATTERN, .rpar},
        {.lsqr, .LIST_CONTENTS_PATTERN, .rsqr},
        {.lcur, .PATTERN_FIELDS, .OPT_ELLIPSIS, .rcur},
    })
    insert_rule(&rule_table, Nonterminal.OPT_ELLIPSIS, {
        {.ellipsis},
        {},
    })
    insert_rule(&rule_table, Nonterminal.PATTERN_FIELDS, {
        {.PATTERN_FIELD, .PATTERN_FIELDS_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.PATTERN_FIELDS_1, {
        {.comma, .PATTERN_FIELD, .PATTERN_FIELDS_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.PATTERN_FIELD, {
        {.alpha_ident_, .PATTERN_FIELD_1},
    })
    insert_rule(&rule_table, Nonterminal.PATTERN_FIELD_1, {
        {.equal, .PATTERN},
        {.OPT_TYPING, .OPT_AS_PATTERN},
    })
    insert_rule(&rule_table, Nonterminal.OPT_AS_PATTERN, {
        {._as, .PATTERN},
        {},
    })
    insert_rule(&rule_table, Nonterminal.LIST_CONTENTS_PATTERN, {
        {.PATTERN, .LIST_CONTENTS_PATTERN_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.LIST_CONTENTS_PATTERN_1, {
        {.comma, .PATTERN, .LIST_CONTENTS_PATTERN_1},
        {},
    })

    // Expressions
    insert_rule(&rule_table, Nonterminal.EXPR, {
        {.HANDLED_EXPR},
        {._raise, .EXPR},
        {._if, .EXPR, ._then, .EXPR, ._else, .EXPR},
        {._while, .EXPR, ._do, .EXPR},
        {._case, .EXPR, ._of, .MATCH},
        {._fn, .MATCH},
    })
    insert_rule(&rule_table, Nonterminal.HANDLED_EXPR, {
        {.ORELSE_EXPR, .HANDLED_EXPR_1}, 
    })
    insert_rule(&rule_table, Nonterminal.HANDLED_EXPR_1, {
        {._handle, .MATCH},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.ORELSE_EXPR, {
        {.ANDALSO_EXPR, .ORELSE_EXPR_1},
    })
    insert_rule(&rule_table, Nonterminal.ORELSE_EXPR_1, {
        {._orelse, .ORELSE_EXPR},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.ANDALSO_EXPR, {
        {.TYPED_EXPR, .ANDALSO_EXPR_1},
    })
    insert_rule(&rule_table, Nonterminal.ANDALSO_EXPR_1, {
        {._andalso, .ANDALSO_EXPR},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.TYPED_EXPR, {
        {.INFIX_EXPR, .OPT_TYPING},
    })
    insert_rule(&rule_table, Nonterminal.INFIX_EXPR, {
        {.APPL_EXPR, .INFIX_EXPR_1},
    })
    insert_rule(&rule_table, Nonterminal.INFIX_EXPR_1, {
        {.sym_ident_, .APPL_EXPR, .INFIX_EXPR_1},
        {}, 
    })
    insert_rule(&rule_table, Nonterminal.APPL_EXPR, {
        {.ATOMIC_EXPR, .ATOMIC_EXPRS},
    })
    insert_rule(&rule_table, Nonterminal.ATOMIC_EXPRS, {
        // order matters, take the first branch if possible
        {.ATOMIC_EXPR, .ATOMIC_EXPRS},
        {},
    })
    insert_rule(&rule_table, Nonterminal.ATOMIC_EXPR, {
        {.literal_},
        {.alpha_ident_}, 
        {.lpar, .PAREN_CONTENTS, .rpar},
        {.lsqr, .LIST_CONTENTS, .rsqr},
        {.lcur, .RECORD_FIELDS, .rcur},
    })
    insert_rule(&rule_table, Nonterminal.PAREN_CONTENTS, {
        {.EXPR, .PAREN_CONTENTS_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.PAREN_CONTENTS_1, {
        {.semi, .EXPR, .EXPR_SEQ_1},
        {.comma, .EXPR, .LIST_CONTENTS_1},
    })
    insert_rule(&rule_table, Nonterminal.RECORD_FIELDS, {
        {.RECORD_FIELD, .RECORD_FIELDS_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.RECORD_FIELDS_1, {
        {.comma, .RECORD_FIELD, .RECORD_FIELDS_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.RECORD_FIELD, {
        {.alpha_ident_, .equal, .EXPR},
    })
    insert_rule(&rule_table, Nonterminal.LIST_CONTENTS, {
        {.EXPR, .LIST_CONTENTS_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.LIST_CONTENTS_1, {
        {.comma, .EXPR, .LIST_CONTENTS},
        {},
    })
    insert_rule(&rule_table, Nonterminal.EXPR_SEQ_1, {
        {.semi, .EXPR, .EXPR_SEQ_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.MATCH, {
        {.MATCH_RULE, .MATCH_1},
    })
    insert_rule(&rule_table, Nonterminal.MATCH_1, {
        // order matters (with a nested match, the inner one extends as far as it can)
        {.pipe, .MATCH_RULE, .MATCH_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.MATCH_RULE, {
        {.PATTERN, .maps_to, .EXPR},
    })

    // Types
    insert_rule(&rule_table, Nonterminal.TYPE, {
        {.TUPLE_TYPE, .TYPE_1},
    })
    insert_rule(&rule_table, Nonterminal.TYPE_1, {
        {.fn_type, .TYPE},
        {},
    })
    insert_rule(&rule_table, Nonterminal.TUPLE_TYPE, {
        {.CONSTRUCTED_TYPE, .TUPLE_TYPE_1},
    })
    insert_rule(&rule_table, Nonterminal.TUPLE_TYPE_1, {
        {.sym_ident_, .TUPLE_TYPE},
        {},
    })
    insert_rule(&rule_table, Nonterminal.CONSTRUCTED_TYPE, {
        {.NON_ALPHA_ATOMIC_TYPES, .alpha_ident_, .CONSTRUCTED_TYPE_1},
    })
    insert_rule(&rule_table, Nonterminal.CONSTRUCTED_TYPE_1, {
        // always greedily try to read more types (i.e. order matters)
        // "the syntax of types binds more tightly than the syntax of expressions"
        {.NON_ALPHA_ATOMIC_TYPES, .alpha_ident_, .CONSTRUCTED_TYPE_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.ATOMIC_TYPE, {
        {.alpha_ident_},
        {.NON_ALPHA_ATOMIC_TYPE},
    })
    insert_rule(&rule_table, Nonterminal.NON_ALPHA_ATOMIC_TYPES, {
        {.NON_ALPHA_ATOMIC_TYPE, .NON_ALPHA_ATOMIC_TYPES},
        {},
    })
    insert_rule(&rule_table, Nonterminal.NON_ALPHA_ATOMIC_TYPE, {
        {.lcur, .TYPE_FIELDS, .rcur},
        {.lpar, .TYPE, .rpar},
    })
    insert_rule(&rule_table, Nonterminal.TYPE_FIELDS, {
        {Nonterminal.TYPE_FIELD, .TYPE_FIELDS_1},
        {},
    })
    insert_rule(&rule_table, Nonterminal.TYPE_FIELDS_1, {
        {.comma, .TYPE_FIELDS},
        {},
    })
    insert_rule(&rule_table, Nonterminal.TYPE_FIELD, {
        {.alpha_ident_, .colon, .TYPE},
    })
}
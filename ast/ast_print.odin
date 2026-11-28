package ast
import "core:fmt"
import str "core:strings"


print_tree :: proc(n: Node, indent: int = 0) {
    spaces, err := str.repeat(" ", indent*2, context.temp_allocator)

    switch v in n.node_variant {
    case ^Decl:
        switch d in v.decl_variant {
        case ^Bad_Decl:
            fmt.printfln("%s%T", spaces, d^)
        case ^Val_Decl:
            fmt.printfln("%sVal_Decl %s", spaces, d.is_rec ? "(recursive) " : "")
            fmt.printfln("%s  pattern=", spaces)
            print_tree(d.lhs, indent+2)
            fmt.printfln("%s  expr=", spaces)
            print_tree(d.rhs, indent+2)
        case ^Fun_Decl:
            print_fun_decl(d, indent)
        case ^Local_Decl:
            fmt.printfln("%s%T", spaces, d^)
        case ^Infix_Decl:
            fmt.printfln("%s%T (%s-assoc, snugness=%d)", 
                spaces, d^, d.is_right_assoc ? "R" : "L", d.snugness)
            fmt.printfln("%s  names=%v", spaces, d.names)
        case ^Empty_Decl:
            fmt.printfln("%s%T", spaces, d^)
        case ^Seq_Decl:
            print_arr_node("Seq_Decl", d.decls[:], indent)
        }
    
    case ^Expr:
        switch e in v.expr_variant {
        case ^Bad_Expr:
            fmt.printfln("%s%T", spaces, e^)
        case ^Literal_Expr:
            fmt.printfln("%s%T: `%v`", spaces, e^, e.value)
        case ^Ident_Expr:
            fmt.printfln("%s%T: `%s`", spaces, e^, e.name)
        case ^Label_Expr:
            fmt.printfln("%s%T: `%s`", spaces, e^, e.label)
        case ^List_Expr:
            print_arr_node("List_Expr", e.elements, indent)
        case ^Tuple_Expr:
            print_arr_node("Tuple_Expr", e.elements, indent)
        case ^Record_Expr:
            print_arr_node("Record_Expr", e.fields, indent)
        case ^Let_Expr:
            fmt.printfln("%s%T: ", spaces, e^)
            print_arr_node("locals", e.locals.decls[:], indent+1)
            fmt.printfln("%s  expr=", spaces)
            print_tree(e.result, indent+2)
        case ^Appl_Expr:
            fmt.printfln("%s%T: ", spaces, e^)
            fmt.printfln("%s  function=", spaces)
            print_tree(e.function, indent+2)
            print_arr_node("args", e.args[:], indent+1)
        case ^Infix_Chain_Expr:
            print_interleaved("Infix_Chain_Expr", e.exprs[:], e.operators[:], indent)
        case ^Infix_Expr:
            fmt.printfln("%s%T: [display unimplemented]", spaces, e^)
        case ^Typed_Expr:
            fmt.printfln("%s%T ", spaces, e^)
            fmt.printfln("%s  expr=", spaces)
            print_tree(e.expr, indent+2)
            fmt.printfln("%s  type=", spaces)
            print_tree(e.type, indent+2)
        case ^Andalso_Expr:
            fmt.printfln("%s%T ", spaces, e^)
            print_tree(e.left, indent+1)
            print_tree(e.right, indent+1)
        case ^Orelse_Expr:
            fmt.printfln("%s%T ", spaces, e^)
            print_tree(e.left, indent+1)
            print_tree(e.right, indent+1)
        case ^Handle_Expr:
            fmt.printfln("%s%T ", spaces, e^)
            fmt.printfln("%s  expr=", spaces)
            print_tree(e.expr, indent+2)
            print_arr_node("rules", e.match.rules[:], indent+1)
        case ^Raise_Expr:
            fmt.printfln("%s%T: ", spaces, e^)
            print_tree(e.raised, indent+1)
        case ^If_Expr:
            fmt.printfln("%s%T ", spaces, e^)
            fmt.printfln("%s  condition=", spaces)
            print_tree(e.condition, indent+2)
            fmt.printfln("%s  true_branch=", spaces)
            print_tree(e.true_branch, indent+2)
            fmt.printfln("%s  false_branch=", spaces)
            print_tree(e.false_branch, indent+2)
        case ^While_Expr:
            fmt.printfln("%s%T ", spaces, e^)
            fmt.printfln("%s  condition=", spaces)
            print_tree(e.condition, indent+2)
            fmt.printfln("%s  body=", spaces)
            print_tree(e.body, indent+2)
        case ^Case_Expr:
            fmt.printfln("%s%T ", spaces, e^)
            fmt.printfln("%s  pattern=", spaces)
            print_tree(e.pattern, indent+2)
            print_arr_node("rules", e.match.rules[:], indent+1)
        case ^Fn_Expr:
            print_arr_node("Fn_Expr: rules", e.match.rules[:], indent)
        case ^Seq_Expr:
            print_arr_node("Seq_Expr", e.exprs, indent)
        case:
            fmt.printfln("%s[undefined expr]", spaces)
        }

    case ^Pattern:
        #partial switch p in v.pattern_variant {
        case ^Bad_Pattern:
            fmt.printfln("%s%T", spaces, p^)
        case ^Literal_Pattern:
            fmt.printfln("%sLiteral_Pattern: `%v`", spaces, p.value)
        case ^Ident_Pattern:
            fmt.printfln("%sIdent_Pattern: `%s`", spaces, p.name)
        case ^Typed_Pattern:
            fmt.printfln("%sTyped_Pattern ", spaces)
            fmt.printfln("%s  pattern=", spaces)
            print_tree(p.pattern, indent+2)
            fmt.printfln("%s  type=", spaces)
            print_tree(p.type, indent+2)
        case:
            fmt.printfln("%s%s", spaces, "[some pattern]")
        }

    case ^Type:
        switch t in v.type_variant {
        case ^Bad_Type:
            fmt.printfln("%s%T", spaces, t^)
        case ^Ident_Type:
            fmt.printfln("%sIdent_Type: `%s`", spaces, t.name)
        case ^Constructed_Type:
            print_arr_node("Constructed_Type", t.args[:], indent)
        case ^Record_Type:
            print_arr_node("Record_Type", t.fields[:], indent)
        case ^Tuple_Type:
            print_arr_node("Tuple_Type", t.components[:], indent)
        case ^Func_Type:
            fmt.printfln("%sFunc_Type: ", spaces)
            fmt.printfln("%s  domain=", spaces)
            print_tree(t.domain, indent+2)
            fmt.printfln("%s  codomain=", spaces)
            print_tree(t.codomain, indent+2)
        }
    
    case ^Node_List:
        print_arr_node("Node_List", v.elements[:], indent)
    case ^Name:
        fmt.printfln("%sName: `%s`, is_symbolic=%b", spaces, v.name, v.is_symbolic)
    case ^Expr_Field:
    case ^Pattern_Field:
    case ^Type_Field:
        fmt.printfln("%sType_Field: `%s`, type=", spaces, v.label)
        print_tree(v.type, indent+1)
    case ^Match:
        print_arr_node("Match", v.rules[:], indent)
    case ^Match_Rule:
        fmt.printfln("%sMatch_Rule", spaces)
        fmt.printfln("%s  pattern=", spaces)
        print_tree(v.pattern, indent+2)
        fmt.printfln("%s  expr=", spaces)
        print_tree(v.expr, indent+2)
    case ^Fun_Arm:
        fmt.printfln("%sFun_Arm", spaces)
        print_arr_node("args", v.args[:], indent+1)
        fmt.printfln("%s  expr=", spaces)
        print_tree(v.expr, indent+2)
    }
}


print_arr_node :: proc(name: string, nodes: $T/[]$E, indent: int = 0) {
    spaces, err := str.repeat(" ", indent*2, context.temp_allocator)

    fmt.printf("%s%s[%d] ", spaces, name, len(nodes))
    fmt.println("{")
    for n in nodes {
        print_tree(n, indent+1)
    }
    fmt.print(spaces)
    fmt.println("}")
}

print_interleaved :: proc(name: string, nodes: $T/[]$E, operators: []string, indent: int = 0) {
    spaces, err := str.repeat(" ", indent*2, context.temp_allocator)

    fmt.printf("%s%s[%d] ", spaces, name, len(nodes))
    fmt.println("{")

    print_tree(nodes[0], indent+1)
    for i in 1..<len(nodes) {
        fmt.printfln("%s(%s)", spaces, operators[i-1])
        print_tree(nodes[i], indent+1)
    }
    fmt.print(spaces)
    fmt.println("}")
}

print_fun_decl :: proc(decl: ^Fun_Decl, indent: int = 0) {
    spaces, err := str.repeat(" ", indent*2, context.temp_allocator)

    fmt.printf("%sFun_Decl[%d] (name: `%s`) ", spaces, len(decl.arms), decl.arms[0].name)
    fmt.println("{")
    for n in decl.arms {
        print_fun_arm(n, indent+1)
    }
    fmt.print(spaces)
    fmt.println("}")
}

print_fun_arm :: proc(arm: ^Fun_Arm, indent: int = 0) {
    spaces, err := str.repeat(" ", indent*2, context.temp_allocator)

    fmt.printfln("%s%s", spaces, "Fun_Arm")
    print_arr_node("args", arm.args[:], indent+1)
    
    fmt.printfln("%s  expr=", spaces)
    print_tree(arm.expr, indent+2)
}

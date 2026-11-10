package ast
import "core:fmt"
import str "core:strings"

Node :: struct {
    offset: int, // starting at 0
    line: int, // starting at 1
    node_variant: Any_Node, // mimics OOP-style polymorphism
}

Any_Node :: union {
    ^Decl,
    ^Expr,
    ^Pattern,
    ^Type,
    ^Node_List,
    ^Name,
    ^Expr_Field,
    ^Pattern_Field,
    ^Type_Field,
}

connect_node :: proc(base: ^Node, variant: Any_Node) {
    base.node_variant = variant
}
connect :: proc {
    connect_node,
    connect_decl,
    connect_expr,
    connect_pattern,
    connect_type,
}


Node_List :: struct {
    using base_node: Node, 
    elements: [dynamic]Node,
}

Name :: struct {
    using base_node: Node,
    name: string,
    is_symbolic: bool,
}
new_name :: proc(name: string, base: Node) -> ^Name {
    name_node := new(Name)
    name_node ^= Name { base_node=base, name=name }
    connect(&name_node.base_node, name_node)
    return name_node
}

Literal_Value :: union { i32, f32, string }

Match_Rule :: struct {
    pattern: Pattern,
    expr: Expr,
}


print_tree :: proc(n: Node, indent: int = 0) {
    spaces, err := str.repeat(" ", indent*2, context.temp_allocator)

    switch v in n.node_variant {
    case ^Decl:
        switch d in v.decl_variant {
        case ^Bad_Decl:
            fmt.printfln("%s%T", spaces, d^)
        case ^Val_Decl:
            fmt.printf("%sVal_Decl ", spaces)
            if d.is_rec do fmt.print("(recursive) ")
            fmt.printfln("\n%s  pattern=", spaces)
            print_tree(d.lhs, indent+2)
            fmt.printfln("%s  expr=", spaces)
            print_tree(d.rhs, indent+2)
        case ^Fun_Decl:
            fmt.printfln("%s%T", spaces, d^)
        case ^Local_Decl:
            fmt.printfln("%s%T", spaces, d^)
        case ^Infix_Decl:
            fmt.printfln("%s%T", spaces, d^)
        case ^Empty_Decl:
            fmt.printfln("%s%T", spaces, d^)
        case ^Seq_Decl:
            print_arr_node("Seq_Decl", d.decls[:], indent)
        }
    
    case ^Expr:
        #partial switch e in v.expr_variant {
        case ^Bad_Expr:
            fmt.printfln("%s%T", spaces, e^)
        case ^Literal_Expr:
            fmt.printfln("%sLiteral_Expr: `%v`", spaces, e.value)
        case ^Ident_Expr:
            fmt.printfln("%sIdent_Expr: `%s`", spaces, e.name)
        case ^Typed_Expr:
            fmt.printfln("%sTyped_Expr ", spaces)
            fmt.printfln("%s  expr=", spaces)
            print_tree(e.expr, indent+2)
            fmt.printfln("%s  type=", spaces)
            print_tree(e.type, indent+2)
        case:
            fmt.printfln("%s%s", spaces, "[some expr]")
        }

    case ^Pattern:
        #partial switch p in v.pattern_variant {
        case ^Bad_Pattern:
            fmt.printfln("%s%T", spaces, p^)
        case ^Literal_Pattern:
            fmt.printfln("%sLiteral_Pattern: `%v`", spaces, p.value)
        case ^Ident_Pattern:
            fmt.printfln("%sIdent_Pattern: `%s`", spaces, p.name)
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
            fmt.printfln("%sFunc_Type: \n%s  domain=", spaces, spaces)
            print_tree(t.domain, indent+2)
            fmt.printfln("%scodomain=", spaces)
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
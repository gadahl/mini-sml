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

Literal_Value :: union { i32, f32, string }

Match_Rule :: struct {
    pattern: Pattern,
    expr: Expr,
}


print_tree :: proc(n: Node, indent: int = 0) {
    spaces, err := str.repeat(" ", indent*2, context.temp_allocator)

    switch v in n.node_variant {
    case ^Decl:
    case ^Expr:
    case ^Pattern:

    case ^Type:
        switch t in v.type_variant {
        case ^Bad_Type:
            fmt.printfln("%sBad_Type", spaces)
        case ^Ident_Type:
            fmt.printfln("%sIdent_Type: name=%s", spaces, t.name)
        case ^Constructed_Type:
            fmt.printfln("%sConstructed_Type (size %d) %s", spaces, len(t.args), "{")
            for e in t.args {
                print_tree(e, indent+1)
            }
        fmt.printfln("%s%s", spaces, "}")
        case ^Record_Type:
            fmt.printfln("%sRecord_Type (size %d) %s", spaces, len(t.fields), "{")
            for e in t.fields {
                print_tree(e, indent+1)
            }
        fmt.printfln("%s%s", spaces, "}")
        case ^Tuple_Type:
            fmt.printfln("%sTuple_Type (size %d) %s", spaces, len(t.components), "{")
            for e in t.components {
                print_tree(e, indent+1)
            }
        fmt.printfln("%s%s", spaces, "}")
        case ^Func_Type:
            fmt.printfln("%sFunc_Type:\n%s  domain=", spaces, spaces)
            print_tree(t.domain, indent+2)
            fmt.printfln("%s  codomain=", spaces)
            print_tree(t.codomain, indent+2)
        }
    
    case ^Node_List:
        fmt.printfln("%sNode_List (size %d) %s", spaces, len(v.elements), "{")
        for e in v.elements {
            print_tree(e, indent+1)
        }
        fmt.printfln("%s%s", spaces, "}")
    case ^Name:
        fmt.printfln("%sName: name=%s, is_symbolic=%b", spaces, v.name, v.is_symbolic)
    case ^Expr_Field:
    case ^Pattern_Field:
    case ^Type_Field:
        fmt.printfln("%sType_Field: name=%s, type=", spaces, v.label)
        print_tree(v.type, indent+1)

    }
}
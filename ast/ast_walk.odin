package ast

import "core:fmt"


AST_Walker :: struct {
    frames: [dynamic]AST_Frame,
}
new_ast_walker :: proc() -> ^AST_Walker {
    frames := make([dynamic]AST_Frame)

    walker := new(AST_Walker)
    walker ^= { frames }
    return walker;
}
free_ast_walker :: proc(walker: ^AST_Walker) {
    for frame in walker.frames {
        delete_ast_frame(frame)
    }
    delete(walker.frames)
    free(walker)
}
walker_get_top_frame :: proc(walker: ^AST_Walker) -> ^AST_Frame {
    return &walker.frames[len(walker.frames)-1]
}

AST_Frame :: struct {
    children: [dynamic]^Node,
    index: int,
}
make_ast_frame :: proc() -> AST_Frame {
    return AST_Frame { 
        children=make([dynamic]^Node),
        index=0,
    }
}
delete_ast_frame :: proc(frame: AST_Frame) {
    delete(frame.children)
}


walk :: proc(root: ^Node) {

    root_frame := make_ast_frame()
    append(&root_frame.children, root)
    
    walker := new_ast_walker()
    defer free_ast_walker(walker)
    append(&walker.frames, root_frame)

    for len(walker.frames) > 0 {

        curr_frame := walker_get_top_frame(walker)

        if curr_frame.index >= len(curr_frame.children) {
            // no children left to traverse, finish up
            pop(&walker.frames)
            if len(walker.frames) == 0 do break

            parent_frame := walker_get_top_frame(walker)
            parent_frame.index += 1
        }
        else {
            // expand this node and go deeper
            curr_child := curr_frame.children[curr_frame.index]

            // temp printing
            print_tree(curr_child^)
            fmt.println()
    
            append(&walker.frames, make_ast_frame())
            new_frame := walker_get_top_frame(walker)
    
            add_children(&new_frame.children, curr_child)
        }
    }
}


add_children :: proc(list: ^[dynamic]^Node, n: ^Node) {
    switch v in n.node_variant {
    case ^Decl:
        switch d in v.decl_variant {
        case ^Bad_Decl: // none
        case ^Val_Decl:
            append(list, &d.lhs.base_node)
            append(list, &d.rhs.base_node)
        case ^Fun_Decl:
            add_node_list(list, d.arms[:])
        case ^Local_Decl:
            append(list, &d.locals.base_node)
            append(list, &d.globals.base_node)
        case ^Infix_Decl: // none
        case ^Empty_Decl: // none
        case ^Seq_Decl:
            add_node_list(list, d.decls[:])
        }
    
    case ^Expr:
        switch e in v.expr_variant {
        case ^Bad_Expr: // none
        case ^Literal_Expr: // none
        case ^Ident_Expr: // none
        case ^Label_Expr: // none
        case ^List_Expr:
            add_node_list(list, e.elements[:])
        case ^Tuple_Expr:
            add_node_list(list, e.elements[:])
        case ^Record_Expr:
            add_node_list(list, e.fields[:])
        case ^Let_Expr:
            append(list, &e.locals.base_node)
            append(list, &e.result.base_node)
        case ^Appl_Expr:
            append(list, &e.function.base_node)
            add_node_list(list, e.args[:])
        case ^Infix_Chain_Expr:
            add_node_list(list, e.exprs[:])
        case ^Infix_Expr:
            append(list, &e.left.base_node)
            append(list, &e.right.base_node)
        case ^Typed_Expr:
            append(list, &e.expr.base_node)
            append(list, &e.type.base_node)
        case ^Andalso_Expr:
            append(list, &e.left.base_node)
            append(list, &e.right.base_node)
        case ^Orelse_Expr:
            append(list, &e.left.base_node)
            append(list, &e.right.base_node)
        case ^Handle_Expr:
            append(list, &e.expr.base_node)
            append(list, &e.match.base_node)
        case ^Raise_Expr:
            append(list, &e.raised.base_node)
        case ^If_Expr:
            append(list, &e.condition.base_node)
            append(list, &e.true_branch.base_node)
            append(list, &e.false_branch.base_node)
        case ^While_Expr:
            append(list, &e.condition.base_node)
            append(list, &e.body.base_node)
        case ^Case_Expr:
            append(list, &e.pattern.base_node)
            append(list, &e.match.base_node)
        case ^Fn_Expr:
            append(list, &e.match.base_node)
        case ^Seq_Expr:
            add_node_list(list, e.exprs[:])
        case:
        }

    case ^Pattern:
        #partial switch p in v.pattern_variant {
        case ^Bad_Pattern: // none
        case ^Literal_Pattern: // none
        case ^Ident_Pattern: // none
        case ^Typed_Pattern:
            append(list, &p.pattern.base_node)
            append(list, &p.type.base_node)
        case:
        }

    case ^Type:
        switch t in v.type_variant {
        case ^Bad_Type: // none
        case ^Ident_Type: // none
        case ^Constructed_Type:
            add_node_list(list, t.args[:])
        case ^Record_Type:
            add_node_list(list, t.fields[:])
        case ^Tuple_Type:
            add_node_list(list, t.components[:])
        case ^Func_Type:
            append(list, &t.domain.base_node)
            append(list, &t.codomain.base_node)
        }
    
    case ^Node_List:
        for &n in v.elements {
            append(list, &n)
        }
    case ^Name: // none
    case ^Expr_Field: // none
    case ^Pattern_Field: // none
    case ^Type_Field:
        append(list, &v.type.base_node)
    case ^Match:
        add_node_list(list, v.rules[:])
    case ^Match_Rule:
        append(list, &v.pattern.base_node)
        append(list, &v.expr.base_node)
    case ^Fun_Arm:
        add_node_list(list, v.args[:])
        append(list, &v.expr.base_node)
    }
}

add_node_list :: proc(list: ^[dynamic]^Node, nodes: $T/[]$E) {
    for n in nodes {
        append(list, &n.base_node)
    }
}

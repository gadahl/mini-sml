package ast
import str "core:strings"

Expr :: struct {
    using base_node: Node, 
	expr_variant: Any_Expr,
}

Any_Expr :: union {
    ^Bad_Expr,
    ^Literal_Expr,
    ^Ident_Expr,
    ^Label_Expr,
    ^Tuple_Expr,
    ^List_Expr,
    ^Record_Expr,
    ^Let_Expr,
    ^Appl_Expr,
    ^Infix_Chain_Expr,
    ^Infix_Expr,
    ^Typed_Expr,
    ^Andalso_Expr,
    ^Orelse_Expr,
    ^Handle_Expr,
    ^Raise_Expr,
    ^If_Expr,
    ^While_Expr,
    ^Case_Expr,
    ^Fn_Expr,
    ^Seq_Expr,
}

connect_expr :: proc(base: ^Expr, variant: Any_Expr) {
    base.expr_variant = variant
    connect_node(&base.base_node, base)
}


// Expressions

Bad_Expr :: struct {
	using base_expr: Expr,
}
new_bad_expr :: proc(base: Node) -> ^Bad_Expr {
    bad := new(Bad_Expr)
    bad ^= { base_node=base }
    connect(&bad.base_expr, bad)
    return bad
}

Literal_Expr :: struct {
	using base_expr: Expr,
	value: Literal_Value,
}
new_literal_expr :: proc(value: Literal_Value, base: Node) -> ^Literal_Expr {
    literal := new(Literal_Expr)
    literal ^= { base_node=base, value=value }
    connect(&literal.base_expr, literal)
    return literal
}

Ident_Expr :: struct {
	using base_expr: Expr,
	name: string,
}
new_ident_expr :: proc(name: string, base: Node) -> ^Ident_Expr {
    ident := new(Ident_Expr)
    ident ^= Ident_Expr { name=name, base_node=base }
    connect(&ident.base_expr, ident)
    return ident
}

Label_Expr :: struct {
	using base_expr: Expr,
	label: string,
}
new_label_expr :: proc(name: string, base: Node) -> ^Label_Expr {
    label := new(Label_Expr)
    label ^= Label_Expr { label=name, base_node=base }
    connect(&label.base_expr, label)
    return label
}

List_Expr :: struct {
	using base_expr: Expr,
	elements: []^Expr,
}
new_list_expr :: proc(elements: []^Expr, base: Node) -> ^List_Expr {
    list := new(List_Expr)
    list ^= List_Expr { elements=elements, base_node=base }
    connect(&list.base_expr, list)
    return list
}

Tuple_Expr :: struct {
    using base_expr: Expr,
    elements: []^Expr,
}
new_tuple_expr :: proc(elements: []^Expr, base: Node) -> ^Tuple_Expr {
    tuple := new(Tuple_Expr)
    tuple ^= Tuple_Expr { elements=elements, base_node=base }
    connect(&tuple.base_expr, tuple)
    return tuple
}

Record_Expr :: struct {
    using base_expr: Expr,
    fields: []^Expr_Field,
}
new_record_expr :: proc(fields: []^Expr_Field, base: Node) -> ^Record_Expr {
    record := new(Record_Expr)
    record ^= Record_Expr { fields=fields, base_node=base }
    connect(&record.base_expr, record)
    return record
}
Expr_Field :: struct {
    using base_node: Node,
    label: string,
    expr: ^Expr,
}
new_expr_field :: proc(label: string, expr: ^Expr) -> ^Expr_Field {
    field := new(Expr_Field)
    field ^= Expr_Field { label=label, base_node=expr.base_node }
    connect(&field.base_node, field)
    return field
}

Let_Expr :: struct {
    using base_expr: Expr,
    locals: ^Seq_Decl,
    result: ^Expr,
}
new_let_expr :: proc(decls: ^Seq_Decl, expr: ^Expr) -> ^Let_Expr {
    let_expr := new(Let_Expr)
    let_expr ^= Let_Expr { locals=decls, result=expr, base_node=decls.base_node }
    connect(&let_expr.base_expr, let_expr)
    return let_expr
}

Appl_Expr :: struct {
    using base_expr: Expr,
    function: ^Expr,
    args: [dynamic]^Expr,
}
new_appl_expr :: proc(function: ^Expr, args: [dynamic]^Expr) -> ^Appl_Expr {
    appl := new(Appl_Expr)
    appl ^= Appl_Expr { function=function, args=args, base_node=function.base_node }
    connect(&appl.base_expr, appl)
    return appl
}

Infix_Chain_Expr :: struct {
    using base_expr: Expr,
    operators: [dynamic]string,
    exprs: [dynamic]^Expr,
}
new_infix_chain_expr :: proc(ops: [dynamic]string, exprs: [dynamic]^Expr) -> ^Infix_Chain_Expr {
    infix_chain := new(Infix_Chain_Expr)
    infix_chain ^= Infix_Chain_Expr { operators=ops, exprs=exprs, base_node=exprs[0].base_node }
    connect(&infix_chain.base_expr, infix_chain)
    return infix_chain
}

Infix_Expr :: struct {
    using base_expr: Expr,
    operator: string,
    left: ^Expr,
    right: ^Expr,
}
new_infix_expr :: proc(op: string, left: ^Expr, right: ^Expr) -> ^Infix_Expr {
    infix := new(Infix_Expr)
    infix ^= Infix_Expr { operator=str.clone(op), left=left, right=right, base_node=left.base_node }
    connect(&infix.base_expr, infix)
    return infix
}

Typed_Expr :: struct {
    using base_expr: Expr,
    expr: ^Expr,
    type: ^Type,
}
new_typed_expr :: proc(expr: ^Expr, ty: ^Type) -> ^Typed_Expr {
    ty_ex := new(Typed_Expr)
    ty_ex ^= Typed_Expr { expr=expr, type=ty, base_node=expr.base_node }
    connect(&ty_ex.base_expr, ty_ex)
    return ty_ex
}

Andalso_Expr :: struct {
    using base_expr: Expr,
    left: ^Expr,
    right: ^Expr,
}

Orelse_Expr :: struct {
    using base_expr: Expr,
    left: ^Expr,
    right: ^Expr,
}

Handle_Expr :: struct {
    using base_expr: Expr,
    expr: ^Expr,
    match: ^Match,
}

Raise_Expr :: struct {
    using base_expr: Expr,
    raised: ^Expr,
}

If_Expr :: struct {
    using base_expr: Expr,
    condition: ^Expr,
    true_branch: ^Expr,
    false_branch: ^Expr, 
}
new_if_expr :: proc(condition: ^Expr, true_branch: ^Expr, false_branch: ^Expr) -> ^If_Expr {
    if_expr := new(If_Expr)
    if_expr ^= If_Expr { 
        condition=condition, true_branch=true_branch, 
        false_branch=false_branch, base_node=condition.base_node 
    }
    connect(&if_expr.base_expr, if_expr)
    return if_expr
}

While_Expr :: struct {
    using base_expr: Expr,
    condition: ^Expr,
    body: ^Expr,
}
new_while_expr :: proc(condition: ^Expr, body: ^Expr) -> ^While_Expr {
    while_expr := new(While_Expr)
    while_expr ^= While_Expr { condition=condition, body=body, base_node=condition.base_node }
    connect(&while_expr.base_expr, while_expr)
    return while_expr
}

Case_Expr :: struct {
    using base_expr: Expr,
    pattern: ^Pattern,
    match: ^Match,
}
new_case_expr :: proc(pattern: ^Pattern, match: ^Match) -> ^Case_Expr {
    case_expr := new(Case_Expr)
    case_expr ^= Case_Expr { pattern=pattern, match=match, base_node=pattern.base_node }
    connect(&case_expr.base_expr, case_expr)
    return case_expr
}

Fn_Expr :: struct {
    using base_expr: Expr,
    match: ^Match,
}
new_fn_expr :: proc(match: ^Match) -> ^Fn_Expr {
    fn_expr := new(Fn_Expr)
    fn_expr ^= Fn_Expr { match=match, base_node=match.base_node }
    connect(&fn_expr.base_expr, fn_expr)
    return fn_expr
}

Seq_Expr :: struct {
    using base_expr: Expr,
    exprs: []^Expr,
}
new_seq_expr :: proc(exprs: []^Expr, base: Node) -> ^Seq_Expr {
    seq_expr := new(Seq_Expr)
    seq_expr ^= Seq_Expr { exprs=exprs, base_node=base }
    connect(&seq_expr.base_expr, seq_expr)
    return seq_expr
}
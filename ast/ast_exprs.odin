package ast


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

List_Expr :: struct {
	using base_expr: Expr,
	elements: []Expr,
}

Tuple_Expr :: struct {
    using base_expr: Expr,
    elements: []Expr,
}

Record_Expr :: struct {
    using base_expr: Expr,
    fields: []Expr_Field,
}
Expr_Field :: struct {
    using base_node: Node,
    label: string,
    expr: ^Expr,
}

Let_Expr :: struct {
    using base_expr: Expr,
    locals: []Decl,
    result: ^Expr,
}

Appl_Expr :: struct {
    using base_expr: Expr,
    function: ^Expr,
    args: []Expr,
}

Infix_Expr :: struct {
    using base_expr: Expr,
    operator: string,
    left: ^Expr,
    right: ^Expr,
}

Typed_Expr :: struct {
    using base_expr: Expr,
    expr: ^Expr,
    type: ^Type,
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
    rules: []Match_Rule,
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

While_Expr :: struct {
    using base_expr: Expr,
    condition: ^Expr,
    body: ^Expr,
}

Case_Expr :: struct {
    using base_expr: Expr,
    pattern: ^Pattern,
    rules: []Match_Rule,
}

Fn_Expr :: struct {
    using base_expr: Expr,
    rules: []Match_Rule,
}

Seq_Expr :: struct {
    using base_expr: Expr,
    exprs: []Expr,
}
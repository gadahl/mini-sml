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
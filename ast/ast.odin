package ast


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
}

Literal_Value :: union { i32, f32, string }

Match_Rule :: struct {
    pattern: Pattern,
    expr: Expr,
}

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
    ^Node_List,
    ^Name,
    ^Expr_Field,
    ^Pattern_Field,
    ^Type_Field,
    ^Match,
    ^Match_Rule,
    ^Fun_Arm,
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

Match :: struct {
    using base_node: Node,
    rules: [dynamic]^Match_Rule,
}
new_match :: proc(rules: [dynamic]^Match_Rule, base: Node) -> ^Match {
    match_node := new(Match)
    match_node ^= Match { base_node=base, rules=rules }
    connect(&match_node.base_node, match_node)
    return match_node
}
Match_Rule :: struct {
    using base_node: Node,
    pattern: ^Pattern,
    expr: ^Expr,
}
new_match_rule :: proc(pattern: ^Pattern, expr: ^Expr) -> ^Match_Rule {
    rule := new(Match_Rule)
    rule ^= Match_Rule { base_node=pattern.base_node, pattern=pattern, expr=expr }
    connect(&rule.base_node, rule)
    return rule
}

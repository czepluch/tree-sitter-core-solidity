; Indent hints for nvim-treesitter. A node matched by @indent.begin contributes
; one level of indent to lines inside it; @indent.end closes it.

[
  (body)
  (expression_body)
  (class_body)
  (instance_body)
  (contract_body)
  (assembly_block)
  (match_stmt)
  (arguments)
  (param_list)
  (type_args)
  (type_params)
  (tuple_expression)
  (parenthesized_expression)
] @indent.begin

[
  "}"
  ")"
  "]"
] @indent.end

[
  "}"
  ")"
  "]"
] @indent.branch

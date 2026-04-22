; Captures consumed by nvim-treesitter-textobjects. Capture names follow
; its documented convention so users get the usual `vaf` / `vif` / `]m`
; / `]a` motions without extra configuration.

; ===== functions =====

(function_decl
  body: (_) @function.inner) @function.outer

(constructor_decl
  body: (_) @function.inner) @function.outer

(lambda_expression
  body: (_) @function.inner) @function.outer

; Class-body signatures have no body but are still function-like for
; purposes of `]m` / `[m` navigation.
(signature) @function.outer

; ===== "class" (contracts, classes, instances, ADTs) =====

(contract_decl body: (_) @class.inner) @class.outer
(class_decl    body: (_) @class.inner) @class.outer
(instance_decl body: (_) @class.inner) @class.outer
(data_decl) @class.outer
(type_synonym) @class.outer

; ===== parameters =====

(param) @parameter.inner
(param) @parameter.outer

; Function-call arguments also behave as parameters for `]a` / `[a`.
(arguments (_) @parameter.inner)
(arguments (_) @parameter.outer)

; ===== calls =====

(call_expression
  arguments: (_) @call.inner) @call.outer

(method_call_expression
  arguments: (_) @call.inner) @call.outer

; ===== conditionals =====

(if_stmt
  consequence: (_) @conditional.inner) @conditional.outer

(ternary_expression) @conditional.outer

(match_stmt) @conditional.outer
(match_arm)  @conditional.outer

; ===== blocks =====

[
  (body)
  (class_body)
  (instance_body)
  (contract_body)
  (assembly_block)
] @block.outer

[
  (body)
  (class_body)
  (instance_body)
  (contract_body)
  (assembly_block)
] @block.inner

; ===== assignments =====

(assign_stmt
  left:  (_) @assignment.lhs
  right: (_) @assignment.rhs)

(compound_assign_stmt
  left:  (_) @assignment.lhs
  right: (_) @assignment.rhs)

(let_decl
  name:  (identifier) @assignment.lhs
  value: (_) @assignment.rhs)

; ===== returns =====

(return_stmt) @return.outer
(return_stmt value: (_) @return.inner)

; ===== comments =====

[
  (line_comment)
  (block_comment)
] @comment.outer

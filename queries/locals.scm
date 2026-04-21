; Scope / definition / reference annotations for locals-based consumers
; (vim-illuminate's treesitter provider, nvim-treesitter-refactor's
; highlight_definitions, etc.).

; ===== scopes =====

(source_file)          @local.scope
(contract_decl)        @local.scope
(contract_body)        @local.scope
(class_decl)           @local.scope
(instance_decl)        @local.scope
(function_decl)        @local.scope
(constructor_decl)     @local.scope
(lambda_expression)    @local.scope
(match_arm)            @local.scope

; ===== definitions =====

; Top-level / contract-level bindings
(function_decl name: (identifier) @local.definition.function)
(signature     name: (identifier) @local.definition.function)
(contract_decl name: (identifier) @local.definition.type)
(class_decl    name: (identifier) @local.definition.type)
(data_decl     name: (identifier) @local.definition.type)
(type_synonym  name: (identifier) @local.definition.type)
(data_variant  name: (identifier) @local.definition.constructor)
(field_decl    name: (identifier) @local.definition.field)

; Local bindings introduced inside bodies
(let_decl name: (identifier) @local.definition.var)
(param    name: (identifier) @local.definition.parameter)

; `forall a b .` binds type variables for the whole surrounding decl.
; Only tag direct identifier children of sig_prefix - constraints have
; their own nested identifiers that shouldn't double-count.
(sig_prefix (identifier) @local.definition.type.parameter)

; Pattern bindings in match arms. A lowercase constructor_pattern head
; with no args introduces a fresh variable binding (Haskell-style).
; Uppercase heads are data constructors and are handled as references.
((constructor_pattern
   name: (identifier) @local.definition.var)
  (#match? @local.definition.var "^[a-z_]"))

; ===== references =====

(identifier) @local.reference

; Scope / definition / reference annotations used by nvim-treesitter to power
; same-identifier highlighting and simple scope-aware lookups.

; ----- scopes -----

(source_file)          @local.scope
(contract_decl)        @local.scope
(contract_body)        @local.scope
(function_decl)        @local.scope
(constructor_decl)     @local.scope
(lambda_expression)    @local.scope
(match_arm)            @local.scope
(instance_decl)        @local.scope
(class_decl)           @local.scope

; ----- definitions -----

(let_decl name: (identifier) @local.definition.var)
(param    name: (identifier) @local.definition.parameter)
(field_decl name: (identifier) @local.definition.field)

(function_decl name: (identifier) @local.definition.function)
(signature     name: (identifier) @local.definition.function)
(data_decl     name: (identifier) @local.definition.type)
(data_variant  name: (identifier) @local.definition.constructor)
(contract_decl name: (identifier) @local.definition.type)
(class_decl    name: (identifier) @local.definition.type)
(type_synonym  name: (identifier) @local.definition.type)

; ----- references -----

(identifier) @local.reference

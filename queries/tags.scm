; Tags for code-outline tools (aerial.nvim, telescope-symbols,
; GitHub code navigation). Each @definition.* captures a range; the
; nested @name capture gives the tool the label text.

(contract_decl
  name: (identifier) @name) @definition.class

(class_decl
  name: (identifier) @name) @definition.interface

(instance_decl
  class: (identifier) @name) @definition.implementation

(function_decl
  name: (identifier) @name) @definition.function

(signature
  name: (identifier) @name) @definition.method

(constructor_decl
  "constructor" @name) @definition.method

(data_decl
  name: (identifier) @name) @definition.type

(type_synonym
  name: (identifier) @name) @definition.type

(data_variant
  name: (identifier) @name) @definition.enum

(field_decl
  name: (identifier) @name) @definition.field

; ===== reference captures (for call-graph views) =====

(call_expression
  function: (identifier) @name) @reference.call

(method_call_expression
  property: (identifier) @name) @reference.call

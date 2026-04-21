; Tree-sitter highlight queries for Core Solidity.
;
; ORDERING: Neovim's treesitter highlighter applies the LAST matching pattern
; when priorities tie. So generic fallbacks go first, specific captures go
; below, and the specific ones win.

; ===== generic fallbacks (must come first) =====

(identifier) @variable

; Capitalization-based heuristics: Core Solidity doesn't distinguish
; constructors/types from variables at the lexical level, but convention is
; PascalCase for types/constructors, lowercase for values.
((identifier) @type
  (#match? @type "^[A-Z]"))

; ===== literals =====

(integer_literal) @number
(hex_literal)     @number.hex
(string_literal)  @string
(escape_sequence) @string.escape

; ===== comments =====

(line_comment)  @comment @spell
(block_comment) @comment @spell

; ===== punctuation =====

[ "(" ")" "{" "}" "[" "]" ] @punctuation.bracket
[ "," ";" "." ":" "|" ]     @punctuation.delimiter

; ===== operators =====

[ "->" "=>" ]                         @operator
[ "=" "+=" "-=" ]                     @operator
[ "==" "!=" "<" ">" "<=" ">=" ]       @operator
[ "&&" "||" "!" ]                     @operator
[ "+" "-" "*" "/" "%" ]               @operator
"@"                                   @operator

; ===== keywords =====

[
  "contract"
  "constructor"
  "function"
  "let"
  "lam"
  "default"
  "pragma"
  "assembly"
] @keyword

"import" @keyword.import
"return" @keyword.return

[ "if" "else" "then" "match" ] @keyword.control

[ "class" "instance" "data" "type" "forall" ] @keyword.type

[
  "no-coverage-condition"
  "no-patterson-condition"
  "no-bounded-variable-condition"
] @keyword.directive

; ===== declarations: binding positions =====

(contract_decl    name: (identifier) @type)
(class_decl       name: (identifier) @type)
(instance_decl    class: (identifier) @type)
(data_decl        name: (identifier) @type)
(type_synonym     name: (identifier) @type)
(data_variant     name: (identifier) @constructor)

(function_decl    name: (identifier) @function)
(signature        name: (identifier) @function)
"constructor"     @function.builtin

; ===== type annotations =====

(type_identifier name: (identifier) @type)
(type_identifier args: (type_args (type_identifier name: (identifier) @type)))
(constraint      class: (identifier) @type)

; forall type variables - they bind a name that's later used as a type
(sig_prefix      (identifier) @type.parameter)
(type_params     (identifier) @type.parameter)

; ===== parameters =====

(param name: (identifier) @variable.parameter)

; ===== fields / members =====

(field_decl       name: (identifier) @variable.member)
(member_expression property: (identifier) @variable.member)

; ===== call sites =====

(call_expression        function: (identifier) @function.call)
(method_call_expression property: (identifier) @function.call)

; Uppercase "call" is a data constructor invocation like `Some(x)` or
; `Method(name, payability, args, rets, fn)` - override @function.call.
((call_expression function: (identifier) @constructor)
  (#match? @constructor "^[A-Z]"))

; ===== patterns =====

(wildcard_pattern) @variable.builtin

; In a constructor pattern, an uppercase head is a data constructor;
; a lowercase head binds a fresh variable.
((constructor_pattern name: (identifier) @constructor)
  (#match? @constructor "^[A-Z]"))

((constructor_pattern name: (identifier) @variable)
  (#match? @variable "^[a-z_]"))

; ===== proxy syntax =====

(proxy_expression "@" @operator)
(proxy_type       "@" @operator)

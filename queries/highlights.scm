; Tree-sitter highlight queries for Core Solidity.
; Capture names follow the standard nvim-treesitter convention; Zed reuses
; the same names via its tree-sitter integration.

; ----- keywords -----

[
  "contract"
  "constructor"
  "function"
  "let"
  "return"
  "if"
  "else"
  "then"
  "match"
  "data"
  "class"
  "instance"
  "forall"
  "default"
  "type"
  "lam"
  "import"
  "pragma"
  "assembly"
] @keyword

[
  "no-coverage-condition"
  "no-patterson-condition"
  "no-bounded-variable-condition"
] @keyword.directive

"return" @keyword.return
"import" @keyword.import

[
  "if"
  "else"
  "then"
  "match"
] @keyword.control

[
  "class"
  "instance"
  "data"
  "type"
  "forall"
] @keyword.type

; ----- operators -----

[
  "->"
  "=>"
] @operator

[
  "="
  "+="
  "-="
] @operator

[
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
] @operator

[
  "&&"
  "||"
  "!"
] @operator

[
  "+"
  "-"
  "*"
  "/"
  "%"
] @operator

"@" @operator

; ----- punctuation -----

[
  "("
  ")"
  "{"
  "}"
  "["
  "]"
] @punctuation.bracket

[
  ","
  ";"
  "."
  ":"
  "|"
] @punctuation.delimiter

; ----- literals -----

(integer_literal) @number
(hex_literal)     @number
(string_literal)  @string
(escape_sequence) @string.escape

; ----- comments -----

(line_comment)  @comment @spell
(block_comment) @comment @spell

; ----- declarations: names -----

(contract_decl    name: (identifier) @type)
(class_decl       name: (identifier) @type)
(instance_decl    class: (identifier) @type)
(data_decl        name: (identifier) @type)
(type_synonym     name: (identifier) @type)
(data_variant     name: (identifier) @constructor)

(function_decl    name: (identifier) @function)
(signature        name: (identifier) @function)
(constructor_decl "constructor" @function.builtin)

; ----- call sites -----

(call_expression function: (identifier) @function.call)
(method_call_expression property: (identifier) @function.call)

; ----- member access -----

(member_expression property: (identifier) @variable.member)

; ----- parameters -----

(param name: (identifier) @variable.parameter)
(lambda_expression (param_list (param name: (identifier) @variable.parameter)))

; ----- field declarations -----

(field_decl name: (identifier) @variable.member)

; ----- type positions -----

(type_identifier name: (identifier) @type)
(constraint      class: (identifier) @type)
(sig_prefix      (identifier) @type.parameter)
(type_params     (identifier) @type.parameter)

; ----- patterns -----

; A constructor pattern starting with an uppercase identifier is a data
; constructor; otherwise it binds a fresh variable (Haskell-style).
((constructor_pattern
   name: (identifier) @constructor)
  (#match? @constructor "^[A-Z]"))

((constructor_pattern
   name: (identifier) @variable)
  (#match? @variable "^[a-z_]"))

(wildcard_pattern) @variable.builtin

; ----- capitalization-based fallback for bare identifiers -----

; Uppercase identifiers in expression position are likely constructors.
((call_expression
   function: (identifier) @constructor)
  (#match? @constructor "^[A-Z]"))

((identifier) @constructor
  (#match? @constructor "^[A-Z]"))

; ----- default variable fallback -----

(identifier) @variable

; Inject tree-sitter-yul inside `assembly { ... }` blocks if available.
; Falls back to no injection (opaque block) if the yul parser is not installed.

((assembly_block) @injection.content
 (#set! injection.language "yul")
 (#set! injection.include-children))

; Tree-sitter honors `//` and `/* */` inside assembly blocks as top-level
; extras already, so comments within assembly keep their comment highlight.

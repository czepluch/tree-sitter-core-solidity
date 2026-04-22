# Working notes for Claude Code

Context that future-you needs when editing this grammar.

## Ground truth

The grammar is derived directly from, and must stay consistent with:

- `~/dev/argot/solcore/src/Solcore/Frontend/Lexer/SolcoreLexer.x`
- `~/dev/argot/solcore/src/Solcore/Frontend/Parser/SolcoreParser.y`

When the Happy parser and a prose spec disagree, trust Happy. The original
bootstrap plan had several inaccuracies that only surfaced after grounding
in the real files (`return` expression is required not optional; class
bodies hold signatures only, not function definitions; `field_decl`
supports initializers; `data` decls require a trailing `;`).

## Iteration loop

```
npx tree-sitter generate     # regenerate src/parser.c from grammar.js
npx tree-sitter test         # run test/corpus/*.txt
npx tree-sitter parse FILE   # smoke-test a single file
```

`src/parser.c`, `src/grammar.json`, `src/node-types.json`, and
`src/tree_sitter/` are generated. Never hand-edit them - edit `grammar.js`
(and `src/scanner.c` for the external scanner) and regenerate.

## Coverage expectations

- Every `.solc` file under `~/dev/argot/solcore/std/` must parse cleanly.
- Every `.solc` file under `~/dev/argot/solcore/test/examples/dispatch/`
  must parse cleanly.
- Across `~/dev/argot/solcore/test/examples/**`, ~94% is the baseline.
  The failing files fall into two buckets:
  - marked `runTestExpectingFailure` in `solcore/test/Cases.hs` - solcore
    itself rejects them; we should not try to accept them either.
  - missing trailing semicolons on `data` decls - real source bugs.
- `~/dev/argot/solcore/blog-post/*.sol` is vanilla Solidity, not Core
  Solidity. Ignore for coverage.

If you change the grammar, run this to confirm:

```bash
total=0; pass=0
for d in ~/dev/argot/solcore/test/examples/*/ ~/dev/argot/solcore/std/; do
  for f in "$d"*.solc; do
    [ -f "$f" ] || continue
    total=$((total+1))
    out=$(npx tree-sitter parse "$f" 2>&1)
    if echo "$out" | rg -q ERROR; then :; else pass=$((pass+1)); fi
  done
done
echo "passed $pass / $total"
```

## Known design decisions

- **Yul is delegated.** `assembly { ... }` parses as brace-balanced opaque
  text in the outer grammar; Yul parsing happens via `queries/injections.scm`
  pointing at `tree-sitter-yul`.
- **Nested block comments need an external scanner.** Tree-sitter's
  regex-based lexer cannot match balanced `/* */` nesting. See `src/scanner.c`.
- **Comparison operators are left-associative.** Happy declares them
  `nonassoc`; tree-sitter needs some associativity to produce a tree. Left
  is the pragmatic choice.
- **Anonymous tokens do not appear in corpus-test expected trees.** E.g.,
  `(unary_expression argument: ...)` - no `operator: "!"` line. Use plain
  `tree-sitter parse` output with positions stripped as the baseline for
  expected sexps.

## Query ordering matters

Neovim's treesitter highlighter applies *the last matching pattern* when
priorities tie. In `queries/highlights.scm`, keep generic fallbacks
(`(identifier) @variable`, capitalization heuristics) at the top and
specific node-based captures (`(function_decl name: ...)`) below. Inverting
this order silently breaks colors - the `@variable` catch-all ends up
painting function names and types.

## Backlog

Feature backlog lives on GitHub issues. When the user asks for the next
thing to work on, check the issue list rather than inventing tasks.

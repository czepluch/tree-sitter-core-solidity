# tree-sitter-core-solidity

A [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar for
[Core Solidity](https://github.com/argotorg/solcore) (`.solc`). Core Solidity
is a research-prototype compiler exploring a new type system for Solidity,
with Haskell-style type classes, ADTs, pattern matching, `forall`
quantifiers, and embedded Yul blocks.

Status: v1. Parses the `std/` and `test/examples/dispatch/` corpus in
`argotorg/solcore` cleanly (including the 47k-line `std/std.solc` stress test).
Coverage on the full `test/examples/**` set sits above 94%; the remaining
failures are files deliberately marked `runTestExpectingFailure` in
`solcore/test/Cases.hs` or files missing semicolons.

## Ground truth

The grammar was written directly against:

- `solcore/src/Solcore/Frontend/Lexer/SolcoreLexer.x` (Alex lexer)
- `solcore/src/Solcore/Frontend/Parser/SolcoreParser.y` (Happy grammar)

When in doubt, those files are the source of truth.

## Repository layout

```
grammar.js                  main grammar
src/scanner.c               external scanner for nested /* */ block comments
queries/
  highlights.scm            syntax highlighting
  injections.scm            Yul injection for assembly { ... } blocks
  folds.scm                 fold regions
  indents.scm               indent hints
  locals.scm                scopes / definitions / references
test/corpus/                48 tree-sitter corpus tests
examples/                   curated .solc files for manual verification
```

## Build

```
npm install
npx tree-sitter generate
npx tree-sitter test
npx tree-sitter parse examples/std.solc
```

`npx tree-sitter test` should report `successful parses: 48; failed parses: 0`.

## Local install - Neovim

Add to your nvim-treesitter setup:

```lua
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.core_solidity = {
  install_info = {
    url = "~/dev/argot/tree-sitter-core-solidity",  -- adjust to your path
    files = { "src/parser.c", "src/scanner.c" },
    branch = "main",
    generate_requires_npm = false,
    requires_generate_from_grammar = false,
  },
  filetype = "solc",
}

vim.filetype.add({
  extension = { solc = "core_solidity" },
})
```

Then `:TSInstallFromGrammar core_solidity`.

Symlink the query files so nvim-treesitter picks them up:

```
mkdir -p ~/.config/nvim/queries/core_solidity
ln -sf ~/dev/argot/tree-sitter-core-solidity/queries/*.scm ~/.config/nvim/queries/core_solidity/
```

## Local install - Zed

Build the wasm parser, then load as a dev extension:

```
npx tree-sitter build --wasm
```

Create an extension directory with the grammar and queries (see
`zed.dev/docs/extensions/languages` for the current schema).

## Yul injection

`queries/injections.scm` injects language `yul` into every `assembly { ... }`
block. If you have `tree-sitter-yul` installed, Yul inside assembly will be
highlighted using its rules. Without it, assembly bodies render with the
default text color.

The outer grammar deliberately parses assembly content as opaque
brace-balanced text - Yul parsing is delegated.

## Scope

In scope for v1:

- Full parser coverage of the `argotorg/solcore` language (minus
  expected-failure files).
- Highlight, fold, indent, locals, and Yul-injection queries.
- Working Neovim integration.

Out of scope:

- LSP features (hover, go-to-def). Those require the real compiler.
- Auto-formatting.
- Publication to the nvim-treesitter registry or Zed extension store.
- Semantic highlighting from type information.

## License

MIT.

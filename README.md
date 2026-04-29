# tree-sitter-core-solidity

A [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar for
[Core Solidity](https://github.com/argotorg/solcore) (`.solc`).

## Quick install (lazy.nvim / LazyVim)

Drop this into `~/.config/nvim/lua/plugins/core-solidity.lua` and restart
Neovim. Lazy clones, compiles, and Neovim picks up the parser and queries
automatically. No `tree-sitter` CLI required, just a C compiler.

```lua
return {
  {
    "czepluch/tree-sitter-core-solidity",
    build = "mkdir -p ~/.local/share/nvim/site/parser && cc -O2 -shared -fPIC -I src src/parser.c src/scanner.c -o ~/.local/share/nvim/site/parser/core_solidity.so",
    ft = "core_solidity",
    dependencies = {
      {
        "czepluch/tree-sitter-yul",
        build = "mkdir -p ~/.local/share/nvim/site/parser && cc -O2 -shared -fPIC -I src src/parser.c -o ~/.local/share/nvim/site/parser/yul.so",
      },
    },
  },
}
```

Verify with `:checkhealth core_solidity` - should report the parser loadable,
all seven queries registered, filetype mapped, and the yul injection parser
present.

Open any `.solc` file, try `:InspectTree` to see the parse tree and
`:Inspect` on a token to see which highlight captures applied.

## What you get

- Syntax highlighting for `.solc` files, with built-in types (`word`,
  `address`, `uint256`, `mapping`, `Proxy`, ...) and constants (`True`,
  `False`) painted distinctly
- Yul highlighting inside `assembly { ... }` via injection into
  [tree-sitter-yul](https://github.com/czepluch/tree-sitter-yul)
- Scope-aware identifier highlighting (`vim-illuminate` etc. light up
  same-scope references) via `locals.scm`
- Textobject motions - `vaf` / `vif` / `vac` / `]m` / `]a` with mini.ai or
  nvim-treesitter-textobjects
- Code folding and symbol outlines via `folds.scm` / `tags.scm`
- 48 passing corpus tests

**Status:** v1. Parses all of `solcore/std/` and
`solcore/test/examples/dispatch/` cleanly, including the 47k-line
`std/std.solc` stress test. ~94% coverage on the full
`solcore/test/examples/` tree - the misses are files deliberately marked
`runTestExpectingFailure` in solcore's own test suite or source with
missing semicolons.

---

## Alternative install paths

### Plain Neovim (manual, no package manager)

Clone the repo somewhere on Neovim's runtime path so the bundled
`ftdetect/` and `queries/core_solidity/` directories get picked up:

```bash
git clone https://github.com/czepluch/tree-sitter-core-solidity \
  ~/.local/share/nvim/site/pack/plugins/start/tree-sitter-core-solidity
cd "$_"
mkdir -p ~/.local/share/nvim/site/parser
cc -O2 -shared -fPIC -I src src/parser.c src/scanner.c \
   -o ~/.local/share/nvim/site/parser/core_solidity.so
```

For the Yul injection, repeat with
<https://github.com/czepluch/tree-sitter-yul> (no `scanner.c` - the Yul
parser only has `parser.c`).

### Development (working on the grammar itself)

```bash
cd ~/dev/argot/tree-sitter-core-solidity
npx tree-sitter generate
npx tree-sitter test                      # should show 48/48 passing
npx tree-sitter build -o ~/.local/share/nvim/site/parser/core_solidity.so
```

Iteration loop after edits:

```bash
npx tree-sitter generate && npx tree-sitter test
npx tree-sitter build -o ~/.local/share/nvim/site/parser/core_solidity.so
# :edit the buffer in Neovim to reload
```

Query file edits are picked up on `:edit` alone - no parser rebuild.

---

## Repository layout

```
grammar.js                  main grammar (~450 lines)
src/
  scanner.c                 external scanner for nested block comments
  parser.c                  generated
  grammar.json              generated
  node-types.json           generated
  tree_sitter/              generated bindings
queries/core_solidity/
  highlights.scm            syntax highlighting
  injections.scm            Yul injection for assembly { ... }
  folds.scm                 fold regions
  indents.scm               indent hints
  locals.scm                scopes / definitions / references
  textobjects.scm           nvim-treesitter-textobjects motions
  tags.scm                  code-outline / ctags symbols
ftdetect/core_solidity.lua  maps .solc -> filetype core_solidity
lua/core_solidity/
  health.lua                :checkhealth core_solidity
test/corpus/                48 tree-sitter corpus tests
examples/                   curated .solc files from solcore
CLAUDE.md                   working notes for maintainers
```

## Ground truth

The grammar is written directly against:

- `solcore/src/Solcore/Frontend/Lexer/SolcoreLexer.x` (Alex lexer)
- `solcore/src/Solcore/Frontend/Parser/SolcoreParser.y` (Happy grammar)

When in doubt, those files are the source of truth. See `CLAUDE.md` for
maintainer-facing notes.

## License

MIT.

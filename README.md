# tree-sitter-core-solidity

A [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar for
[Core Solidity](https://github.com/argotorg/solcore) (`.solc`). Core Solidity
is a research-prototype compiler exploring a new type system for Solidity,
with Haskell-style type classes, ADTs, pattern matching, `forall`
quantifiers, and embedded Yul blocks.

**Status:** v1. Parses all of `solcore/std/` and
`solcore/test/examples/dispatch/` cleanly, including the 47k-line
`std/std.solc` stress test. ~94% coverage on the full `solcore/test/examples/`
tree - the misses are files marked `runTestExpectingFailure` in solcore's own
test suite or source with missing semicolons.

## What you get

- Syntax highlighting for `.solc` files
- Yul highlighting inside `assembly { ... }` blocks (via injection into
  [tree-sitter-yul](https://github.com/czepluch/tree-sitter-yul))
- Code folding for contracts, classes, instances, functions, match
  statements, and match arms
- Scope-aware identifier highlighting (cursor on a variable lights up other
  occurrences in scope) via `locals.scm`
- 48 passing corpus tests

---

## Install - LazyVim (Neovim)

Drop this into `~/.config/nvim/lua/plugins/core-solidity.lua`:

```lua
return {
  {
    "czepluch/tree-sitter-core-solidity",
    build = function(plugin)
      local out = vim.fn.stdpath("data") .. "/site/parser/core_solidity.so"
      vim.fn.mkdir(vim.fn.fnamemodify(out, ":h"), "p")
      vim.fn.system({
        "cc", "-O2", "-shared", "-fPIC",
        "-I", plugin.dir .. "/src",
        plugin.dir .. "/src/parser.c",
        plugin.dir .. "/src/scanner.c",
        "-o", out,
      })
    end,
    event = { "BufReadPre *.solc", "BufNewFile *.solc" },
    config = function(plugin)
      vim.filetype.add({ extension = { solc = "core_solidity" } })
      local lang = "core_solidity"
      for _, name in ipairs({ "highlights", "injections", "folds", "indents", "locals" }) do
        local f = io.open(plugin.dir .. "/queries/" .. name .. ".scm", "r")
        if f then
          vim.treesitter.query.set(lang, name, f:read("*a"))
          f:close()
        end
      end
    end,
  },
}
```

Restart Neovim. Lazy.nvim will clone the repo, compile the parser, and
register the grammar + queries automatically. No `tree-sitter` CLI is
needed on the consumer side - just a C compiler (`cc`).

### Yul injection (optional but recommended)

For Yul inside `assembly { ... }` blocks to be highlighted, install the Yul
parser the same way:

```lua
{
  "czepluch/tree-sitter-yul",
  build = function(plugin)
    local out = vim.fn.stdpath("data") .. "/site/parser/yul.so"
    vim.fn.mkdir(vim.fn.fnamemodify(out, ":h"), "p")
    vim.fn.system({
      "cc", "-O2", "-shared", "-fPIC",
      "-I", plugin.dir .. "/src",
      plugin.dir .. "/src/parser.c",
      "-o", out,
    })
  end,
  config = function(plugin)
    local f = io.open(plugin.dir .. "/queries/highlights.scm", "r")
    if f then
      vim.treesitter.query.set("yul", "highlights", f:read("*a"))
      f:close()
    end
  end,
},
```

Without this, assembly bodies render as plain text - no errors, just no
color inside the block.

### Verify

Open any `.solc` file and run:

```
:InspectTree
```

A tree view appears on the right. You should see `contract_decl`,
`function_decl`, etc., and (if you installed the Yul parser) nested Yul
nodes inside `assembly_block` subtrees.

`:Inspect` with the cursor on any token lists which highlight captures
applied - useful for understanding why something did or didn't get a color.

---

## Install - plain Neovim (no LazyVim)

Works with `lazy.nvim`, `packer`, `vim-plug`, or even no package manager -
the parser and queries just need to land in Neovim's runtime dirs.

### With lazy.nvim

Same plugin spec as the LazyVim section above, loaded through lazy.nvim
directly. Lazy.nvim and LazyVim are different things - LazyVim is a
preconfigured distribution, lazy.nvim is just the plugin manager. If you
already use `require("lazy").setup({...})`, append the spec.

### Manual (no package manager)

```bash
# 1. clone
git clone https://github.com/czepluch/tree-sitter-core-solidity ~/.local/share/tree-sitter-core-solidity
cd ~/.local/share/tree-sitter-core-solidity

# 2. compile the parser into Neovim's parser dir
mkdir -p ~/.local/share/nvim/site/parser
cc -O2 -shared -fPIC -I src src/parser.c src/scanner.c \
   -o ~/.local/share/nvim/site/parser/core_solidity.so

# 3. install the queries
mkdir -p ~/.config/nvim/queries/core_solidity
ln -sf "$PWD"/queries/*.scm ~/.config/nvim/queries/core_solidity/
```

Then add the filetype mapping to your `init.lua`:

```lua
vim.filetype.add({
  extension = { solc = "core_solidity" },
})
```

Restart Neovim and open a `.solc` file. `:InspectTree` to verify.

For the Yul injection, repeat the same steps with
<https://github.com/czepluch/tree-sitter-yul> (no `scanner.c` needed -
the Yul parser only has `parser.c`).

---

## Install - Development (from a local checkout)

If you're hacking on the grammar itself, skip Lazy and point it at your
working copy:

```bash
cd ~/dev/argot/tree-sitter-core-solidity
npx tree-sitter generate
npx tree-sitter test                      # should show 48/48 passing

mkdir -p ~/.local/share/nvim/site/parser
npx tree-sitter build -o ~/.local/share/nvim/site/parser/core_solidity.so

mkdir -p ~/.config/nvim/queries/core_solidity
ln -sf "$PWD"/queries/*.scm ~/.config/nvim/queries/core_solidity/
```

Filetype registration still needs a small plugin spec - same `vim.filetype.add`
call as above, but without the `build` hook.

Iteration loop:

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
queries/
  highlights.scm            syntax highlighting
  injections.scm            Yul injection for assembly { ... }
  folds.scm                 fold regions
  indents.scm               indent hints
  locals.scm                scopes / definitions / references
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

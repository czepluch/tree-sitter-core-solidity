-- Health check for tree-sitter-core-solidity. Surfaced via
-- `:checkhealth core_solidity`. Reports whether the parser is loadable,
-- whether each query file is registered, and whether the optional Yul
-- injection parser is available.

local M = {}

local QUERY_NAMES = {
  "highlights",
  "injections",
  "folds",
  "indents",
  "locals",
  "textobjects",
  "tags",
}

function M.check()
  vim.health.start("core_solidity")

  -- Parser
  local ok, err = pcall(vim.treesitter.language.add, "core_solidity")
  if ok then
    vim.health.ok("parser 'core_solidity' is loadable")
  else
    vim.health.error(
      "parser 'core_solidity' not loadable: " .. tostring(err),
      {
        "Run :Lazy build tree-sitter-core-solidity to rebuild the parser.",
        "Check that a C compiler (cc / clang / gcc) is on PATH.",
      }
    )
    return
  end

  -- Queries
  for _, name in ipairs(QUERY_NAMES) do
    local q = vim.treesitter.query.get("core_solidity", name)
    if q then
      vim.health.ok(name .. ".scm registered")
    else
      vim.health.warn(
        name .. ".scm not registered",
        { "Re-run the plugin's config function (usually via :Lazy reload tree-sitter-core-solidity)." }
      )
    end
  end

  -- Filetype mapping
  local ft = vim.filetype.match({ filename = "probe.solc" })
  if ft == "core_solidity" then
    vim.health.ok("filetype 'solc' maps to 'core_solidity'")
  else
    vim.health.warn(
      "filetype for .solc is '" .. tostring(ft) .. "' (expected 'core_solidity')",
      { "Ensure vim.filetype.add was called - see plugin config." }
    )
  end

  -- Yul injection (optional)
  local yul_ok = pcall(vim.treesitter.language.add, "yul")
  if yul_ok then
    vim.health.ok("yul parser found - assembly blocks will be highlighted")
  else
    vim.health.info(
      "yul parser not installed - assembly blocks render as plain text. "
        .. "Install czepluch/tree-sitter-yul for nested highlighting."
    )
  end
end

return M

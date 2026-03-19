---@module "kanagawa.api"

local M = {}

-- ---------------------------------------------------------------------------
-- Internal: scheme registry
-- ---------------------------------------------------------------------------

---@type table<string, table>
local schemes = {
  wave = require "kanagawa.schemes.wave",
  lotus = require "kanagawa.schemes.lotus",
  dragon = require "kanagawa.schemes.dragon",
}

-- ---------------------------------------------------------------------------
-- Internal: deep clone + deep merge
-- ---------------------------------------------------------------------------

---Deep-clone a table. Non-table values are returned as-is.
---@param t table
---@return table
local function deep_clone(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = type(v) == "table" and deep_clone(v) or v
  end
  return copy
end

---Deep-merge `src` into `dst` (mutates `dst`).
---Nested tables are merged recursively. Array entries can be overridden by
---index (e.g. `{ [1] = "#ff0000" }` replaces only the first element).
---@param dst table
---@param src table
---@return table dst
local function deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

-- ---------------------------------------------------------------------------
-- Internal: scheme name validation
-- ---------------------------------------------------------------------------

---@type string[]
local valid_names = {}
for name in pairs(schemes) do
  valid_names[#valid_names + 1] = name
end
table.sort(valid_names)

---@param name string
local function validate_scheme_name(name)
  if not schemes[name] then
    error(
      ("kanagawa: invalid scheme %q — expected one of: %s"):format(
        tostring(name),
        table.concat(valid_names, ", ")
      ),
      3
    )
  end
end

-- ---------------------------------------------------------------------------
-- Public: base preset tables (read-only references for backward compat)
-- ---------------------------------------------------------------------------

M.wave = schemes.wave
M.lotus = schemes.lotus
M.dragon = schemes.dragon

-- ---------------------------------------------------------------------------
-- Public: get(name [, overrides])
-- ---------------------------------------------------------------------------

---Return a **new** scheme table, optionally deep-merged with user overrides.
---The base preset is never mutated.
---
---@param name string Scheme name: `"wave"`, `"lotus"`, or `"dragon"`.
---@param overrides? table Partial table deep-merged into the cloned scheme.
---@return table scheme A fresh table suitable for `config.colors`.
function M.get(name, overrides)
  validate_scheme_name(name)
  local result = deep_clone(schemes[name])
  if overrides then
    deep_merge(result, overrides)
  end
  return result
end

-- ---------------------------------------------------------------------------
-- Public: apply_to_config(config [, opts])
-- ---------------------------------------------------------------------------

---Resolve a scheme (with optional overrides) and assign it to
---`config.colors`.
---
---@param config table WezTerm config builder.
---@param opts? table Options table.
---  - `scheme`    (string?)  Scheme name. Defaults to `"wave"`.
---  - `overrides` (table?)   Partial overrides deep-merged into the scheme.
function M.apply_to_config(config, opts)
  opts = opts or {}
  local name = opts.scheme or "wave"
  config.colors = M.get(name, opts.overrides)
end

return M

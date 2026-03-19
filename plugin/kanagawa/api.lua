---@module "kanagawa.api"

-- ---------------------------------------------------------------------------
-- LuaLS type definitions (from WezTerm config.colors spec)
-- ---------------------------------------------------------------------------

---A WezTerm color reference: either a named `{ Color = "#rrggbb" }` or
---an `{ AnsiColor = "Name" }` table.
---@alias kanagawa.ColorRef { Color: string } | { AnsiColor: string }

---Tab bar button styling (active_tab, inactive_tab, new_tab, and their
---hover variants).
---@class kanagawa.TabStyle
---@field bg_color string
---@field fg_color string
---@field intensity? "Half"|"Normal"|"Bold"
---@field underline? "None"|"Single"|"Double"
---@field italic? boolean
---@field strikethrough? boolean

---The `tab_bar` sub-table inside `config.colors`.
---@class kanagawa.TabBar
---@field background string
---@field inactive_tab_edge string
---@field active_tab kanagawa.TabStyle
---@field inactive_tab kanagawa.TabStyle
---@field inactive_tab_hover kanagawa.TabStyle
---@field new_tab kanagawa.TabStyle
---@field new_tab_hover kanagawa.TabStyle

---A complete WezTerm color scheme suitable for `config.colors`.
---@class kanagawa.Scheme
---@field background string
---@field foreground string
---@field cursor_bg string
---@field cursor_fg string
---@field cursor_border string
---@field selection_fg string
---@field selection_bg string
---@field scrollbar_thumb string
---@field split string
---@field ansi string[]
---@field brights string[]
---@field indexed table<integer, string>
---@field compose_cursor string
---@field visual_bell string
---@field copy_mode_active_highlight_bg kanagawa.ColorRef
---@field copy_mode_active_highlight_fg kanagawa.ColorRef
---@field copy_mode_inactive_highlight_bg kanagawa.ColorRef
---@field copy_mode_inactive_highlight_fg kanagawa.ColorRef
---@field quick_select_label_bg kanagawa.ColorRef
---@field quick_select_label_fg kanagawa.ColorRef
---@field quick_select_match_bg kanagawa.ColorRef
---@field quick_select_match_fg kanagawa.ColorRef
---@field input_selector_label_bg kanagawa.ColorRef  Nightly builds only.
---@field input_selector_label_fg kanagawa.ColorRef  Nightly builds only.
---@field launcher_label_bg kanagawa.ColorRef  Nightly builds only.
---@field launcher_label_fg kanagawa.ColorRef  Nightly builds only.
---@field tab_bar kanagawa.TabBar

---Options for `apply_to_config`.
---@class kanagawa.ApplyOpts
---@field scheme? string Scheme name. Defaults to `"wave"`.
---@field overrides? kanagawa.Scheme Partial overrides deep-merged into the scheme.

---@alias kanagawa.SchemeName "wave"|"lotus"|"dragon"

---Map internal scheme names to display names used in
---`config.color_scheme` and `config.color_schemes`.
---@type table<kanagawa.SchemeName, string>
local display_names = {
  wave = "Kanagawa Wave",
  lotus = "Kanagawa Lotus",
  dragon = "Kanagawa Dragon",
}

---@class kanagawa.Api
---@field wave kanagawa.Scheme Base Wave preset (shared reference).
---@field lotus kanagawa.Scheme Base Lotus preset (shared reference).
---@field dragon kanagawa.Scheme Base Dragon preset (shared reference).
local M = {}

-- ---------------------------------------------------------------------------
-- Internal: scheme registry
-- ---------------------------------------------------------------------------

---@type table<kanagawa.SchemeName, kanagawa.Scheme>
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
---@param name kanagawa.SchemeName Scheme name: `"wave"`, `"lotus"`, or `"dragon"`.
---@param overrides? kanagawa.Scheme Partial table deep-merged into the cloned scheme.
---@return kanagawa.Scheme scheme A fresh table suitable for `config.colors`.
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

---Resolve a scheme (with optional overrides), register it in
---`config.color_schemes` under its display name, and set
---`config.color_scheme` to that name.
---
---This follows WezTerm's own precedence model: `color_scheme` wins over
---`colors`, so the user can still layer extra per-key tweaks through
---`config.colors` and they will act as overrides on top of the scheme.
---
---@param config table WezTerm config builder.
---@param opts? kanagawa.ApplyOpts Options table.
function M.apply_to_config(config, opts)
  opts = opts or {}
  local name = opts.scheme or "wave"
  validate_scheme_name(name)

  local scheme = M.get(name, opts.overrides)
  local label = display_names[name]

  config.color_schemes = config.color_schemes or {}
  config.color_schemes[label] = scheme
  config.color_scheme = label
end

return M

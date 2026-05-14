---@module "kanagawa.api"

-- ---------------------------------------------------------------------------
-- LuaLS type definitions (from WezTerm config.colors spec)
-- ---------------------------------------------------------------------------

---A WezTerm color reference: either a named `{ Color = "#rrggbb" }` or
---an `{ AnsiColor = "Name" }` table.
---@alias kanagawa.ColorRef { Color: string } | { AnsiColor: string }

---Tab bar button style for active, inactive, new-tab, and hover states.
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

---Options accepted by `apply_to_config`.
---@class kanagawa.ApplyOpts
---@field scheme? string Scheme name. Defaults to `"wave"`.
---@field overrides? kanagawa.Scheme Partial overrides deep-merged into the scheme.

---Options accepted by `register`.
---@class kanagawa.RegisterOpts
---@field overrides? kanagawa.Scheme Partial overrides deep-merged into every scheme.
---@field scheme_overrides? table<string, kanagawa.Scheme> Per-scheme overrides keyed by scheme name.

---Per-appearance overrides for `apply_by_appearance`.
---@class kanagawa.AppearanceOverrides
---@field light? kanagawa.Scheme Overrides applied when the light role is selected.
---@field dark? kanagawa.Scheme Overrides applied when the dark role is selected.
---@field fallback? kanagawa.Scheme Overrides applied when the fallback role is selected.

---Options accepted by `apply_by_appearance`.
---@class kanagawa.AppearanceApplyOpts
---@field light? string Scheme name used for light appearances. Defaults to `"lotus"`.
---@field dark? string Scheme name used for dark appearances. Defaults to `"wave"`.
---@field fallback? string Scheme name used when appearance is unknown. Defaults to `"wave"`.
---@field overrides? kanagawa.AppearanceOverrides Role-based overrides.
---@field appearance? string Explicit appearance string for testing or manual selection.

---@alias kanagawa.SchemeName "wave"|"lotus"|"dragon"

---Map internal scheme names to display names used in
---`config.color_scheme` and `config.color_schemes`.
---@type table<kanagawa.SchemeName, string>
local display_names = {
  wave = "Kanagawa Wave",
  lotus = "Kanagawa Lotus",
  dragon = "Kanagawa Dragon",
}

---@type kanagawa.SchemeName[]
local scheme_order = { "wave", "dragon", "lotus" }

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
---@param level? integer
local function validate_scheme_name(name, level)
  if not schemes[name] then
    error(
      ("kanagawa: invalid scheme %q — expected one of: %s"):format(
        tostring(name),
        table.concat(valid_names, ", ")
      ),
      level or 3
    )
  end
end

---@class kanagawa.ResolvedScheme
---@field label string
---@field scheme kanagawa.Scheme

---Resolve a scheme name into its WezTerm display label and cloned scheme.
---@param name kanagawa.SchemeName
---@param overrides? kanagawa.Scheme
---@return kanagawa.ResolvedScheme
local function resolve_scheme(name, overrides)
  validate_scheme_name(name, 4)

  local scheme = deep_clone(schemes[name])
  if overrides then
    deep_merge(scheme, overrides)
  end

  return {
    label = display_names[name],
    scheme = scheme,
  }
end

---Merge global and per-scheme overrides without mutating either input table.
---@param global? kanagawa.Scheme
---@param specific? kanagawa.Scheme
---@return kanagawa.Scheme?
local function merge_override_options(global, specific)
  if not global then
    return specific
  end
  if not specific then
    return global
  end

  local merged = deep_clone(global)
  deep_merge(merged, specific)
  return merged
end

---Read the current WezTerm appearance if GUI APIs are available.
---@return string?
local function get_wezterm_appearance()
  local ok, wezterm_module = pcall(require, "wezterm")
  if not ok or type(wezterm_module) ~= "table" then
    return nil
  end

  local gui = wezterm_module.gui
  if type(gui) ~= "table" or type(gui.get_appearance) ~= "function" then
    return nil
  end

  local appearance_ok, appearance = pcall(gui.get_appearance)
  if not appearance_ok or type(appearance) ~= "string" then
    return nil
  end

  return appearance
end

---@param appearance? string
---@return "light"|"dark"|"fallback"
local function classify_appearance(appearance)
  if type(appearance) ~= "string" then
    return "fallback"
  end

  local normalized = string.lower(appearance)
  if normalized:find("light", 1, true) then
    return "light"
  end
  if normalized:find("dark", 1, true) then
    return "dark"
  end

  return "fallback"
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

---Return a fresh scheme table, optionally deep-merged with user overrides.
---The base preset is never mutated.
---
---@param name kanagawa.SchemeName Scheme name: `"wave"`, `"lotus"`, or `"dragon"`.
---@param overrides? kanagawa.Scheme Partial table deep-merged into the cloned scheme.
---@return kanagawa.Scheme scheme A fresh table suitable for `config.colors`.
function M.get(name, overrides)
  return resolve_scheme(name, overrides).scheme
end

-- ---------------------------------------------------------------------------
-- Public: register(config [, opts])
-- ---------------------------------------------------------------------------

---Register all Kanagawa schemes in `config.color_schemes` without activating
---one through `config.color_scheme`.
---
---`opts.overrides` applies to every registered scheme. `opts.scheme_overrides`
---can apply additional per-scheme overrides keyed by `wave`, `dragon`, or
---`lotus`; per-scheme overrides win over global overrides.
---
---@param config table WezTerm config builder.
---@param opts? kanagawa.RegisterOpts Options table.
function M.register(config, opts)
  opts = opts or {}
  local scheme_overrides = opts.scheme_overrides or {}

  for name in pairs(scheme_overrides) do
    validate_scheme_name(name)
  end

  config.color_schemes = config.color_schemes or {}

  for _, name in ipairs(scheme_order) do
    local overrides = merge_override_options(opts.overrides, scheme_overrides[name])
    local resolved = resolve_scheme(name, overrides)
    config.color_schemes[resolved.label] = resolved.scheme
  end
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
  local resolved = resolve_scheme(name, opts.overrides)

  config.color_schemes = config.color_schemes or {}
  config.color_schemes[resolved.label] = resolved.scheme
  config.color_scheme = resolved.label
end

-- ---------------------------------------------------------------------------
-- Public: apply_by_appearance(config [, opts])
-- ---------------------------------------------------------------------------

---Apply a scheme selected from WezTerm's current light/dark appearance.
---
---`opts.appearance` takes precedence and is intended for tests or explicit
---manual selection. When it is omitted, this function uses
---`wezterm.gui.get_appearance()` if available. Unknown or unavailable
---appearances use the fallback scheme.
---
---@param config table WezTerm config builder.
---@param opts? kanagawa.AppearanceApplyOpts Options table.
function M.apply_by_appearance(config, opts)
  opts = opts or {}
  local appearance = opts.appearance or get_wezterm_appearance()
  local role = classify_appearance(appearance)
  local scheme = opts[role] or (role == "light" and "lotus" or "wave")
  local overrides = opts.overrides and opts.overrides[role] or nil

  M.apply_to_config(config, {
    scheme = scheme,
    overrides = overrides,
  })
end

return M

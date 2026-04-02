---@diagnostic disable: undefined-global
-- luacheck: globals describe it assert

local api = require "kanagawa.api"

-- ── Helpers ────────────────────────────────────────────────────────────

---Recursively compare two tables for value equality.
---@param a table
---@param b table
---@return boolean
local function deep_equal(a, b)
  if a == b then
    return true
  end
  if type(a) ~= "table" or type(b) ~= "table" then
    return false
  end
  for k, v in pairs(a) do
    if not deep_equal(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

---Collect all keys from a table (recursively for nested tables, flattened
---with dot-separated paths).
---@param t table
---@param prefix? string
---@return table<string, boolean>
local function collect_keys(t, prefix)
  prefix = prefix or ""
  local keys = {}
  for k, v in pairs(t) do
    local path = prefix == "" and tostring(k) or (prefix .. "." .. tostring(k))
    keys[path] = true
    if type(v) == "table" then
      for nested_path in pairs(collect_keys(v, path)) do
        keys[nested_path] = true
      end
    end
  end
  return keys
end

-- ── Top-level preset exports ──────────────────────────────────────────

describe("top-level preset exports", function()
  it("exposes wave, lotus, and dragon tables", function()
    assert.is_table(api.wave)
    assert.is_table(api.lotus)
    assert.is_table(api.dragon)
  end)

  it("each preset has the expected core fields", function()
    for _, name in ipairs { "wave", "lotus", "dragon" } do
      local scheme = api[name]
      assert.is_string(scheme.background)
      assert.is_string(scheme.foreground)
      assert.is_table(scheme.ansi)
      assert.is_table(scheme.brights)
      assert.is_table(scheme.tab_bar)
    end
  end)

  it("all schemes expose the same set of keys", function()
    local wave_keys = collect_keys(api.wave)
    for _, name in ipairs { "lotus", "dragon" } do
      local other_keys = collect_keys(api[name])
      for k in pairs(wave_keys) do
        assert.is_true(
          other_keys[k] ~= nil,
          ("key %q present in wave but missing in %s"):format(k, name)
        )
      end
      for k in pairs(other_keys) do
        assert.is_true(
          wave_keys[k] ~= nil,
          ("key %q present in %s but missing in wave"):format(k, name)
        )
      end
    end
  end)

  it("ansi and brights arrays have exactly 8 entries each", function()
    for _, name in ipairs { "wave", "lotus", "dragon" } do
      assert.equal(8, #api[name].ansi)
      assert.equal(8, #api[name].brights)
    end
  end)
end)

-- ── get(name) ─────────────────────────────────────────────────────────

describe("get", function()
  it("returns a table equal in content to the preset", function()
    local result = api.get "wave"
    assert.is_true(deep_equal(result, api.wave))
  end)

  it("returns a new table each time (clone)", function()
    local a = api.get "wave"
    local b = api.get "wave"
    assert.is_not.equal(a, b) -- different references
  end)

  it("accepts all valid scheme names", function()
    for _, name in ipairs { "wave", "lotus", "dragon" } do
      assert.is_table(api.get(name))
    end
  end)

  it("errors on an invalid scheme name", function()
    assert.has_error(function()
      api.get "invalid"
    end)
  end)

  it("error message includes the invalid name and valid options", function()
    local ok, err = pcall(api.get, "typo")
    assert.is_false(ok)
    assert.matches("typo", err)
    assert.matches("wave", err)
    assert.matches("lotus", err)
    assert.matches("dragon", err)
  end)

  it("errors when called without a name", function()
    assert.has_error(function()
      api.get(nil)
    end)
  end)

  it("mutating returned table does not affect the preset", function()
    local result = api.get "wave"
    result.background = "#000000"
    result.tab_bar.active_tab.bg_color = "#000000"
    result.ansi[1] = "#000000"

    assert.is_not.equal("#000000", api.wave.background)
    assert.is_not.equal("#000000", api.wave.tab_bar.active_tab.bg_color)
    assert.is_not.equal("#000000", api.wave.ansi[1])
  end)

  it("mutating returned table does not affect future get() calls", function()
    local first = api.get "dragon"
    first.background = "#000000"

    local second = api.get "dragon"
    assert.is_not.equal("#000000", second.background)
    assert.equal(api.dragon.background, second.background)
  end)
end)

-- ── get(name, overrides) — deep merge ─────────────────────────────────

describe("get with overrides", function()
  it("overrides a top-level string field", function()
    local result = api.get("wave", { background = "#000000" })
    assert.equal("#000000", result.background)
    -- rest is preserved
    assert.equal(api.wave.foreground, result.foreground)
  end)

  it("partially overrides a nested table (tab_bar)", function()
    local result = api.get("wave", {
      tab_bar = { background = "#111111" },
    })
    assert.equal("#111111", result.tab_bar.background)
    -- other tab_bar keys preserved
    assert.equal(api.wave.tab_bar.inactive_tab_edge, result.tab_bar.inactive_tab_edge)
    assert.is_table(result.tab_bar.active_tab)
  end)

  it("overrides 3 levels deep (tab_bar.active_tab.bg_color)", function()
    local result = api.get("wave", {
      tab_bar = { active_tab = { bg_color = "#ff0000" } },
    })
    assert.equal("#ff0000", result.tab_bar.active_tab.bg_color)
    -- sibling key in active_tab preserved
    assert.equal(api.wave.tab_bar.active_tab.fg_color, result.tab_bar.active_tab.fg_color)
    -- sibling table in tab_bar preserved
    assert.equal(api.wave.tab_bar.inactive_tab.bg_color, result.tab_bar.inactive_tab.bg_color)
  end)

  it("partially overrides an array by index (ansi)", function()
    local result = api.get("wave", { ansi = { [1] = "#ffffff" } })
    assert.equal("#ffffff", result.ansi[1])
    -- other indices preserved
    for i = 2, #api.wave.ansi do
      assert.equal(api.wave.ansi[i], result.ansi[i])
    end
  end)

  it("partially overrides the brights array by index", function()
    local result = api.get("dragon", { brights = { [3] = "#aaaaaa" } })
    assert.equal("#aaaaaa", result.brights[3])
    assert.equal(api.dragon.brights[1], result.brights[1])
  end)

  it("overrides indexed colors (non-sequential keys)", function()
    local result = api.get("wave", { indexed = { [16] = "#123456" } })
    assert.equal("#123456", result.indexed[16])
    -- other indexed entry preserved
    assert.equal(api.wave.indexed[17], result.indexed[17])
  end)

  it("overrides a { Color = ... } highlight value", function()
    local result = api.get("wave", {
      copy_mode_active_highlight_bg = { Color = "#abcdef" },
    })
    assert.equal("#abcdef", result.copy_mode_active_highlight_bg.Color)
  end)

  it("with empty overrides table behaves like get(name)", function()
    local plain = api.get "lotus"
    local with_empty = api.get("lotus", {})
    assert.is_true(deep_equal(plain, with_empty))
  end)

  it("does not mutate the base preset", function()
    local original_bg = api.wave.background
    api.get("wave", { background = "#ff0000" })
    assert.equal(original_bg, api.wave.background)
  end)

  it("does not mutate nested preset tables", function()
    local original_tab_bg = api.wave.tab_bar.background
    api.get("wave", { tab_bar = { background = "#ff0000" } })
    assert.equal(original_tab_bg, api.wave.tab_bar.background)
  end)

  it("does not mutate preset arrays", function()
    local original_first = api.wave.ansi[1]
    api.get("wave", { ansi = { [1] = "#ff0000" } })
    assert.equal(original_first, api.wave.ansi[1])
  end)
end)

-- ── apply_to_config ───────────────────────────────────────────────────

describe("apply_to_config", function()
  it("registers the default scheme and sets color_scheme", function()
    local config = {}
    api.apply_to_config(config)
    assert.equal("Kanagawa Wave", config.color_scheme)
    assert.is_table(config.color_schemes)
    assert.is_table(config.color_schemes["Kanagawa Wave"])
    assert.is_true(deep_equal(config.color_schemes["Kanagawa Wave"], api.wave))
  end)

  it("registers a named scheme with its display name", function()
    local config = {}
    api.apply_to_config(config, { scheme = "dragon" })
    assert.equal("Kanagawa Dragon", config.color_scheme)
    assert.is_true(deep_equal(config.color_schemes["Kanagawa Dragon"], api.dragon))
  end)

  it("applies overrides into the registered scheme", function()
    local config = {}
    api.apply_to_config(config, {
      scheme = "lotus",
      overrides = { background = "#000000" },
    })
    assert.equal("Kanagawa Lotus", config.color_scheme)
    assert.equal("#000000", config.color_schemes["Kanagawa Lotus"].background)
    assert.equal(api.lotus.foreground, config.color_schemes["Kanagawa Lotus"].foreground)
  end)

  it("does not touch config.colors", function()
    local config = { colors = { custom_key = "#abcdef" } }
    api.apply_to_config(config, { scheme = "wave" })
    -- colors stays as the user left it
    assert.equal("#abcdef", config.colors.custom_key)
    assert.is_nil(config.colors.background)
  end)

  it("preserves pre-existing color_schemes entries", function()
    local config = {
      color_schemes = { ["My Other Theme"] = { background = "#111111" } },
    }
    api.apply_to_config(config, { scheme = "wave" })
    assert.is_table(config.color_schemes["My Other Theme"])
    assert.equal("#111111", config.color_schemes["My Other Theme"].background)
    assert.is_table(config.color_schemes["Kanagawa Wave"])
  end)

  it("errors on an invalid scheme name", function()
    assert.has_error(function()
      api.apply_to_config({}, { scheme = "nope" })
    end)
  end)
end)

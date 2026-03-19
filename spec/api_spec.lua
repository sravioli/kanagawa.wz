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
  it("sets config.colors to the default (wave) scheme", function()
    local config = {}
    api.apply_to_config(config)
    assert.is_table(config.colors)
    assert.is_true(deep_equal(config.colors, api.wave))
  end)

  it("sets config.colors to a named scheme", function()
    local config = {}
    api.apply_to_config(config, { scheme = "dragon" })
    assert.is_true(deep_equal(config.colors, api.dragon))
  end)

  it("applies overrides when provided", function()
    local config = {}
    api.apply_to_config(config, {
      scheme = "lotus",
      overrides = { background = "#000000" },
    })
    assert.equal("#000000", config.colors.background)
    assert.equal(api.lotus.foreground, config.colors.foreground)
  end)

  it("errors on an invalid scheme name", function()
    assert.has_error(function()
      api.apply_to_config({}, { scheme = "nope" })
    end)
  end)
end)

# kanagawa.wz

[![Awesome](https://awesome.re/mentioned-badge.svg)](https://github.com/michaelbrusegard/awesome-wezterm)
[![Tests](https://img.shields.io/github/actions/workflow/status/sravioli/kanagawa.wz/tests.yaml?label=Tests&logo=Lua)](https://github.com/sravioli/kanagawa.wz/actions?workflow=tests)
[![Lint](https://img.shields.io/github/actions/workflow/status/sravioli/kanagawa.wz/lint.yaml?label=Lint&logo=Lua)](https://github.com/sravioli/kanagawa.wz/actions?workflow=lint)
[![Coverage](https://img.shields.io/coverallsCoverage/github/sravioli/kanagawa.wz?label=Coverage&logo=coveralls)](https://coveralls.io/github/sravioli/kanagawa.wz)

[Kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) color schemes for
[WezTerm](https://wezfurlong.org/wezterm/).

Kanagawa ships three variants:

| Variant    | Background | Description           |
| ---------- | ---------- | --------------------- |
| `wave`     | `#1F1F28`  | Default dark theme    |
| `dragon`   | `#181616`  | Darker, muted variant |
| `lotus`    | `#F2ECBC`  | Light theme           |

## Installation

```lua
local wezterm = require "wezterm"

-- from git
local kanagawa = wezterm.plugin.require "https://github.com/sravioli/kanagawa.wz"

-- from a local checkout
local kanagawa = wezterm.plugin.require(
  "file:///" .. wezterm.config_dir .. "/plugins/kanagawa.wz"
)
```

### Type annotations

Kanagawa ships LuaCATS annotations. After installing
[wezterm-types](https://github.com/DrKJeff16/wezterm-types), annotate the import
to get completion and type checking:

```lua
---@type Kanagawa
local kanagawa = wezterm.plugin.require("https://github.com/sravioli/kanagawa.wz")
```

## Usage

### apply_to_config

This is the usual entry point. It resolves a scheme (default: `"wave"`), applies
any overrides, registers the result in `config.color_schemes`, and sets
`config.color_scheme` to the matching display name.

Because WezTerm's `color_scheme` takes precedence over `colors`, you can
still use `config.colors` to layer additional per-key tweaks on top of the
scheme.

```lua
-- use the default wave scheme
kanagawa.apply_to_config(config)

-- pick a different scheme
kanagawa.apply_to_config(config, { scheme = "dragon" })

-- pick a scheme and override some colors
kanagawa.apply_to_config(config, {
  scheme = "lotus",
  overrides = {
    background = "#ffffff",
    tab_bar = { background = "#e0e0e0" },
  },
})

-- further per-key tweaks via config.colors still work
config.colors = {
  cursor_bg = "#ff0000",
}
```

| Option      | Type    | Default  | Description                                   |
| ----------- | ------- | -------- | --------------------------------------------- |
| `scheme`    | string? | `"wave"` | Scheme name: `"wave"`, `"lotus"`, `"dragon"`. |
| `overrides` | table?  | `nil`    | Partial table deep-merged into the scheme.    |

Display names registered in `config.color_schemes`:

| Scheme   | Display name      |
| -------- | ----------------- |
| `wave`   | `Kanagawa Wave`   |
| `lotus`  | `Kanagawa Lotus`  |
| `dragon` | `Kanagawa Dragon` |

### get

Returns a new scheme table every time. You can modify the result without
changing the shared presets. When you pass overrides, they are deep-merged into
that copy.

```lua
-- get a clean copy of the dragon scheme
local colors = kanagawa.get "dragon"

-- get wave with a single ANSI color replaced
local colors = kanagawa.get("wave", {
  ansi = { [1] = "#ff0000" },
})

-- override a nested tab_bar field
local colors = kanagawa.get("wave", {
  tab_bar = { active_tab = { bg_color = "#000000" } },
})

config.colors = colors
```

### Direct preset access

The base preset tables are also exported directly for quick read access. They
are shared references, so avoid mutating them. Use `get()` when you need a copy.

```lua
config.colors = kanagawa.wave
config.colors = kanagawa.lotus
config.colors = kanagawa.dragon
```

## Override semantics

Overrides use a deep merge:

- Nested tables (e.g. `tab_bar`, `active_tab`) are merged recursively.
  You only need to specify the keys you want to change.
- Array-like tables (`ansi`, `brights`) support partial index overrides.
  For example `{ ansi = { [3] = "#00ff00" } }` replaces only the third
  ANSI color; the remaining seven are preserved.
- Unknown keys are passed through to WezTerm without validation.

`get()` and `apply_to_config()` never mutate the base preset tables.

> **How `apply_to_config` interacts with WezTerm's precedence**
> The plugin registers the resolved scheme in `config.color_schemes` and sets
> `config.color_scheme`. WezTerm evaluates `color_scheme` first and applies
> `colors` afterward, so any keys in `config.colors` override the scheme.

## API

| Export                                 | Description                                             |
| -------------------------------------- | ------------------------------------------------------- |
| `kanagawa.wave`                        | Base Wave preset (shared reference).                    |
| `kanagawa.lotus`                       | Base Lotus preset (shared reference).                   |
| `kanagawa.dragon`                      | Base Dragon preset (shared reference).                  |
| `kanagawa.get(name, overrides?)`       | Return a fresh scheme table with optional overrides.    |
| `kanagawa.apply_to_config(cfg, opts?)` | Register scheme in `cfg.color_schemes` and activate it. |

## License

Code is licensed under the [GNU General Public License v2](../LICENSE).
Documentation is licensed under
[Creative Commons Attribution-NonCommercial 4.0 International](../LICENSE-DOCS).

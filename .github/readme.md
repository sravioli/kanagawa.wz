# kanagawa.wz

[![Tests](https://img.shields.io/github/actions/workflow/status/sravioli/kanagawa.wz/tests.yaml?label=Tests&logo=Lua)](https://github.com/sravioli/kanagawa.wz/actions?workflow=tests)
[![Lint](https://img.shields.io/github/actions/workflow/status/sravioli/kanagawa.wz/lint.yaml?label=Lint&logo=Lua)](https://github.com/sravioli/kanagawa.wz/actions?workflow=lint)
[![Coverage](https://img.shields.io/coverallsCoverage/github/sravioli/kanagawa.wz?label=Coverage&logo=coveralls)](https://coveralls.io/github/sravioli/kanagawa.wz)

[Kanagawa](https://github.com/rebelot/kanagawa.nvim)-inspired color schemes
for [WezTerm](https://wezfurlong.org/wezterm/).

Three variants are included:

| Variant    | Background | Description           |
| ---------- | ---------- | --------------------- |
| **wave**   | `#1F1F28`  | Default dark theme    |
| **dragon** | `#181616`  | Darker, muted variant |
| **lotus**  | `#F2ECBC`  | Light theme           |

## Installation

```lua
local wezterm = require "wezterm"
local kanagawa = wezterm.plugin.require "https://github.com/sravioli/kanagawa.wz"

local config = wezterm.config_builder()

kanagawa.apply_to_config(config)

return config
```

For a local checkout:

```lua
local kanagawa = wezterm.plugin.require(
  "file:///" .. wezterm.config_dir .. "/plugins/kanagawa.wz"
)
```

## Usage

### apply_to_config

The simplest way to use the plugin. Resolves a scheme (default: `"wave"`),
optionally deep-merges user overrides, registers the result in
`config.color_schemes` under a display name (e.g. `"Kanagawa Wave"`), and
sets `config.color_scheme` to that name.

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

Returns a **new** scheme table every time, so you can safely modify the
result. When overrides are provided they are deep-merged into the clone.

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

The base preset tables are also exported directly for quick read access.
These are **shared references** — avoid mutating them. Use `get()` if you
need a mutable copy.

```lua
config.colors = kanagawa.wave
config.colors = kanagawa.lotus
config.colors = kanagawa.dragon
```

## Override semantics

Overrides use a **deep merge**:

- Nested tables (e.g. `tab_bar`, `active_tab`) are merged recursively.
  You only need to specify the keys you want to change.
- Array-like tables (`ansi`, `brights`) support partial index overrides.
  For example `{ ansi = { [3] = "#00ff00" } }` replaces only the third
  ANSI color; the remaining seven are preserved.
- Unknown keys are passed through to WezTerm without validation.

The base preset tables are **never mutated** by `get()` or
`apply_to_config()`.

> **How `apply_to_config` interacts with WezTerm's precedence** —
> The plugin registers the resolved scheme in `config.color_schemes` and
> sets `config.color_scheme`. Because WezTerm evaluates `color_scheme`
> first and then applies `colors` on top, any keys you set in
> `config.colors` act as overrides on the scheme.

## API reference

| Export                                 | Description                                             |
| -------------------------------------- | ------------------------------------------------------- |
| `kanagawa.wave`                        | Base Wave preset (shared reference).                    |
| `kanagawa.lotus`                       | Base Lotus preset (shared reference).                   |
| `kanagawa.dragon`                      | Base Dragon preset (shared reference).                  |
| `kanagawa.get(name, overrides?)`       | Return a fresh scheme table with optional overrides.    |
| `kanagawa.apply_to_config(cfg, opts?)` | Register scheme in `cfg.color_schemes` and activate it. |

## License

Code is licensed under the [GNU General Public License v2](../LICENSE). Documentation
is licensed under [Creative Commons Attribution-NonCommercial 4.0 International](../LICENSE-DOCS).

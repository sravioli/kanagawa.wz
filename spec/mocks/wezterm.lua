--- Minimal wezterm mock for Busted tests.
--- The plugin bootstrap (`plugin/init.lua`) requires `wezterm` and calls
--- `wezterm.plugin.list()`. In unit-test mode we bypass the bootstrap
--- entirely and require `kanagawa.api` directly (the `.busted` lpath
--- already points at `plugin/`), so this mock only needs to satisfy
--- the global `wezterm` reference if any module touches it.

local wezterm = {
  plugin = {
    list = function()
      return {}
    end,
  },
  log_info = function() end,
  log_warn = function() end,
  log_error = function() end,
}

-- make globally accessible
_G.wezterm = wezterm

return wezterm

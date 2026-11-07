local wezterm = require 'wezterm'
local act = wezterm.action

return {
  keys = {
    { key = 't',     mods = 'SHIFT|CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 't',     mods = 'SUPER',      action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w',     mods = 'SHIFT|CTRL', action = act.CloseCurrentTab { confirm = true } },
    { key = 'w',     mods = 'SUPER',      action = act.CloseCurrentTab { confirm = true } },

    { key = 'r',     mods = 'LEADER',     action = act.ReloadConfiguration },
    { key = 't',     mods = 'LEADER',     action = act.ShowLauncher },
    { key = '-',     mods = 'LEADER',     action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = '|',     mods = 'LEADER',     action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'x',     mods = 'LEADER',     action = wezterm.action.CloseCurrentPane { confirm = true }, },
    { key = 'h',     mods = 'LEADER',     action = act.ActivatePaneDirection 'Left' },
    { key = 'j',     mods = 'LEADER',     action = act.ActivatePaneDirection 'Down' },
    { key = 'k',     mods = 'LEADER',     action = act.ActivatePaneDirection 'Up' },
    { key = 'l',     mods = 'LEADER',     action = act.ActivatePaneDirection 'Right' },
  },

  key_tables = {
    copy_mode = {
    },

    search_mode = {
    },
  }
}

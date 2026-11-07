local wezterm = require 'wezterm'

local function update_right_status(window, pane)
  local elms = {}

  if window:leader_is_active() then
    table.insert(elms, { Text = 'LEADER!' })
  end

  window:set_right_status(wezterm.format(elms))
end

wezterm.on('update-status', function(window, pane)
  update_right_status(window, pane)
end)

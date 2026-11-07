local wezterm = require 'wezterm'
local act = wezterm.action

return {
  -- 選択した文字列を右クリックでコピー、無選択状態で右クリックでペースト
  {
    event = { Down = { streak = 1, button = "Right"} },
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ""
      if has_selection then
        window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
      end
    end),
  }
}

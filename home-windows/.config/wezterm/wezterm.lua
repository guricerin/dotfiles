-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- カスタムモジュール
local keybinds = require 'keybinds'
local mousebinds = require 'mousebinds'
require 'status'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
  config.launch_menu = {
    {
      label = 'PowerShell',
      args = { 'pwsh.exe', '-NoLogo' },
    },
  }
  -- unix系の場合は設定されているログインシェルを起動
end

-- Ctrl + c でのコピーや Ctrl + v でのペーストを有効にする
config.swallow_mouse_click_on_window_focus = true

config.mouse_bindings = mousebinds

-- カーソルを点滅させる
config.default_cursor_style = 'BlinkingBlock'

-- keys
config.leader = { key = 's', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = keybinds.keys
config.key_tables = keybinds.key_tables

-- colors
config.color_scheme = 'Catppuccin Mocha'
config.window_background_opacity = 0.85

-- font
config.font = wezterm.font('HackGenNerd', { weight = 'Regular', stretch = 'Normal', style = 'Normal' })
config.font_size = 13.0

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  local index = ''
  if #tabs > 1 then
    index = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
  end

  return index .. 'wezterm'
end)

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

-- ベルが鳴ってから、まだ開いていないタブの tab_id
-- イベントごとに Lua の状態が分かれることがあるので、ローカル変数ではなく wezterm.GLOBAL に置く
wezterm.GLOBAL.bell_tabs = wezterm.GLOBAL.bell_tabs or {}

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local index = tab.tab_index + 1
  local pane = tab.active_pane
  -- シェルが OSC 7 を送っていないなどで取れないことがある
  local cwd = pane.current_working_dir and basename(pane.current_working_dir.file_path) or '?'

  -- e.g. 1: project_dir
  local title = index .. ': ' .. cwd

  -- タブを開いたら目立たせるのをやめる
  local key = tostring(tab.tab_id)
  if tab.is_active then
    wezterm.GLOBAL.bell_tabs[key] = nil
  end

  if wezterm.GLOBAL.bell_tabs[key] then
    return {
      { Background = { Color = '#fab387' } },
      { Foreground = { Color = '#1e1e2e' } },
      { Text = ' ' .. wezterm.nerdfonts.md_bell_ring .. ' ' .. title .. ' ' },
    }
  end
  return {
    { Text = ' ' .. title .. ' ' },
  }
end)

-- Claude Code のフック（Notification・Stop）がベルを鳴らす
wezterm.on('bell', function(window, pane)
  wezterm.GLOBAL.bell_tabs[tostring(pane:tab():tab_id())] = true
  -- ベルだけではタブが描き直されないので、右のステータスを変えて描き直させる
  -- （次の update-status で status.lua が元に戻す）
  window:set_right_status(' ')
end)

-- and finally, return the configuration to wezterm
return config

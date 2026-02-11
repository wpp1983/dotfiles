-- WezTerm config (match Windows Terminal look & current setup)
-- Docs: https://wezfurlong.org/wezterm/config/files.html

local wezterm = require 'wezterm'

local config = {}

-- Font: unified with Windows Terminal
config.font = wezterm.font('Maple Mono NF CN')
config.font_size = 13.0

-- Cursor similar to Windows Terminal (bar)
config.default_cursor_style = 'SteadyBar'

-- Padding similar to Windows Terminal: "6, 6, 6, 6"
config.window_padding = {
  left = 6,
  right = 6,
  top = 6,
  bottom = 6,
}

-- Color scheme: TokyoNight (custom, aligned with Windows Terminal scheme we added)
config.color_schemes = {
  TokyoNightCustom = {
    foreground = '#c0caf5',
    background = '#1a1b26',
    cursor_bg = '#c0caf5',
    cursor_fg = '#1a1b26',
    cursor_border = '#c0caf5',
    selection_bg = '#33467c',
    selection_fg = '#c0caf5',

    ansi = {
      '#15161e', -- black
      '#f7768e', -- red
      '#9ece6a', -- green
      '#e0af68', -- yellow
      '#7aa2f7', -- blue
      '#bb9af7', -- purple
      '#7dcfff', -- cyan
      '#a9b1d6', -- white
    },
    brights = {
      '#414868', -- brightBlack
      '#f7768e', -- brightRed
      '#9ece6a', -- brightGreen
      '#e0af68', -- brightYellow
      '#7aa2f7', -- brightBlue
      '#bb9af7', -- brightPurple
      '#7dcfff', -- brightCyan
      '#c0caf5', -- brightWhite
    },
  },
}
config.color_scheme = 'TokyoNightCustom'

-- Default shell
config.default_prog = { 'pwsh.exe', '-NoLogo' }

-- Launch menu for quick access
config.launch_menu = {
  { label = 'PowerShell (pwsh)', args = { 'pwsh.exe', '-NoLogo' } },
  { label = 'Ubuntu (WSL)', args = { 'wsl.exe', '-d', 'Ubuntu' } },
  { label = 'Command Prompt', args = { 'cmd.exe' } },
}

-- Window decorations (keep simple)
config.window_decorations = 'RESIZE'

-- Keybindings
-- Ctrl+Shift+L: open launcher (shows launch_menu entries, including WSL)
-- Ctrl+Shift+T: new tab
-- Leader-based splits/navigation (tmux-like): Ctrl+a then key
-- Leader key
-- Avoid Ctrl+a (readline) and Ctrl+Space (often bound by IME/window managers).
-- Use Ctrl+g (rarely used interactively; similar to "cancel" in some tools).
config.leader = { key = 'g', mods = 'CTRL', timeout_milliseconds = 1000 }

-- Smart paste: if clipboard contains an image, save it to a file and paste the file path.
-- Also supports FileDropList (copied files) -> paste first file path.
local function smart_paste(window, pane)
  local ok, out, err = pcall(function()
    return wezterm.run_child_process {
      'pwsh.exe',
      '-NoProfile',
      '-Command',
      [[
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$dir = Join-Path $env:USERPROFILE 'Pictures\Screenshots'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
  $list = [System.Windows.Forms.Clipboard]::GetFileDropList()
  if ($list.Count -gt 0) { $list[0]; exit 0 }
}

if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
  $img = [System.Windows.Forms.Clipboard]::GetImage()
  $name = 'wezterm-clip-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.png'
  $path = Join-Path $dir $name
  $img.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $path
  exit 0
}

# Fallback: paste text
Get-Clipboard -Raw
      ]],
    }
  end)

  if ok and out and #out > 0 then
    -- Normalize line endings and avoid trailing newlines
    out = out:gsub('\r\n', '\n'):gsub('\r', '\n')
    out = out:gsub('\n+$', '')
    window:perform_action(wezterm.action.SendString(out), pane)
  else
    -- If something goes wrong, fall back to normal paste
    window:perform_action(wezterm.action.PasteFrom 'Clipboard', pane)
  end
end

config.keys = {
  -- Clipboard
  { key = 'C', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'V', mods = 'CTRL|SHIFT', action = wezterm.action_callback(smart_paste) },

  { key = 'L', mods = 'CTRL|SHIFT', action = wezterm.action.ShowLauncher },
  { key = 'T', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },

  -- Splits (tmux-like)
  -- Note: For LEADER shortcuts, tap Ctrl+a then release Ctrl, then press the key.
  { key = 'v', mods = 'LEADER', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 's', mods = 'LEADER', action = wezterm.action.SplitVertical   { domain = 'CurrentPaneDomain' } },

  -- Splits (direct, no leader; easier muscle memory on Windows)
  { key = 'v', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 's', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.SplitVertical   { domain = 'CurrentPaneDomain' } },

  -- Navigate panes
  { key = 'h', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Right' },

  -- Close pane (confirm)
  { key = 'x', mods = 'LEADER', action = wezterm.action.CloseCurrentPane { confirm = true } },

  -- Zoom pane (toggle)
  { key = 'z', mods = 'LEADER', action = wezterm.action.TogglePaneZoomState },
}

return config

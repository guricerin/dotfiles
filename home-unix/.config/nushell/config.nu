# config.nu
#
# Installed by:
# version = "0.103.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.
# `source $nu.config-path` can reload this file.

$env.PATH = (
  $env.PATH
  # my bin
  | prepend ($env.HOME | path join "bin")
  # Rust
  | prepend ($env.HOME | path join ".cargo/bin")
  | uniq
)

# config
$env.XDG_CONFIG_HOME = $env.HOME | path join ".config"

# fzf
$env.FZF_DEFAULT_COMMAND = 'fd -H -E .git'
## 検索結果はターミナルの下側に表示させる
$env.FZF_DEFAULT_OPTS = "--reverse --height=90%"
## CTRL + T でカレントディレクトリ以下のファイルをプレビュー表示しつつ曖昧検索
$env.FZF_CTRL_T_COMMAND = 'fd --type f -H -E .git'
$env.FZF_CTRL_T_OPTS = '--preview "head -100 {}"'

# Go
$env.GOPATH = (go env GOPATH)

$env.config = {
  keybindings: [
    {
      name: fzf_history
      modifier: control
      keycode: char_r
      mode: [emacs, vi_normal, vi_insert]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "commandline edit --replace (
            history
              | get command
              | reverse
              | uniq
              | str join (char -i 0)
              | fzf --scheme=history --read0 --layout=reverse --height=90% -q (commandline)
              | decode utf-8
              | str trim
            )"
        }
      ]
    }
    {
      name: cd_fuzzy_ghq
      modifier: control
      keycode: char_g
      mode: emacs
      event: {
        send: ExecuteHostCommand,
        cmd: "cd (ghq list --full-path | fzf | decode utf-8 | str trim)"
      }
    }
  ]
}

alias l = ls -al
alias g = git
alias f = fzf
alias d = docker
alias dc = docker compose
alias k = kubectl
alias tf = terraform

# starship: プロンプト改造
## ↓は最終行に書くこと
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

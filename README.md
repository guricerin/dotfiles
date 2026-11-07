# dotfiles

- 次のディレクトリ配下のファイルを参照するシムリンクを、`$HOME`（Windows では `%USERPROFILE%`）に再帰的に作成する

| ディレクトリ | 置くもの | リンクする OS |
|---|---|---|
| [home-common](./home-common/) | どの OS でも使うもの（Claude Code、git、starship、vim、SSH、editorconfig） | すべて |
| [home-unix](./home-unix/) | macOS・Linux でだけ使うもの（zsh、bash、tmux、sheldon、nushell、mise） | macOS・Linux（[setup.sh](./setup.sh)） |
| [home-windows](./home-windows/) | Windows でだけ使うもの（PowerShell、WezTerm、VS Code、`.wslconfig`、git の Windows 用の設定） | Windows（[setup.ps1](./setup.ps1)） |

- home-common と OS 専用のディレクトリの両方に同じパスのファイルを置くと、setup はエラーで止まる
- 意図しないファイルがリポジトリに含まれるのを防止したいので、ディレクトリのシムリンクは作成しない

## Before Setup

### Install depends

```sh
sudo apt update
sudo apt install build-essential procps curl file git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- https://github.com/Homebrew/install
- https://docs.brew.sh/Homebrew-on-Linux#requirements

### SSH setting of GitHub

```sh
mkdir -p ~/.ssh/keys/github
ssh-keygen -t ed25519 -f ~/.ssh/keys/github/id_ed25519
cat ~/.ssh/keys/github/id_ed25519.pub
# paste pub-key to GitHub -> Settings -> SSH and GPG keys -> SSH keys
```

### Clone this repo

```sh
cd $HOME
# ~/.ssh/config は setup 後にリンクされるので、この時点では使う鍵を直接指定する
GIT_SSH_COMMAND='ssh -i ~/.ssh/keys/github/id_ed25519' git clone git@github.com:guricerin/dotfiles.git
```

## Setup

### dry-run

```sh
./setup.sh --dry-run
```

### apply

```sh
./setup.sh
```

張るリンクを表示したあと、続けるかを聞く。聞かずに apply するときは `--yes`（`-y`）を付ける。

## After Setup

### Install tools

```sh
./scripts/depends.sh
mise install
```

`depends.sh` で brew のツールと mise、uv tool のツールを入れてから、`mise install` で [~/.config/mise/config.toml](./home-unix/.config/mise/config.toml) に書いたツールを入れる。`mise use --global` でツールを足すと、リンク先のこのリポジトリのファイルが書き換わるので、コミットする。

### ツールの入れ分け

| 入れる先 | 入れるもの | 例 |
|---|---|---|
| mise（`~/.config/mise/config.toml`） | 言語のランタイムや、プロジェクトごとにバージョンを固定したいツール | bun, python, ruby, go, terraform, kubectl |
| brew（`scripts/depends.sh`） | どのプロジェクトでも同じものを使い、最新版で困らない CLI ツール。シェルや mise 本体も含む | zsh, gh, ripgrep, fzf, mise |
| uv tool（`scripts/depends.sh`） | brew にない Python 製の CLI ツール。`~/.local/bin` に入る | skillspector |
| 公式のインストーラ | 公式のバージョン管理ツールがあるもの | Rust（rustup） |

- mise はリポジトリの `mise.toml` でバージョンを切り替えられる。brew はまとめて `brew upgrade` できる
- 同じツールを mise と brew の両方に入れない。PATH の順番で動くほうが変わり、バージョンの食い違いに気づきにくい（brew が依存関係として入れる python などは除く）
- 迷ったら brew に入れ、バージョンで困ったら mise に移す
- Rust は [rustup](https://rustup.rs/) で入れる。プロジェクトごとのバージョンは `rust-toolchain.toml` で固定できる

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Set zsh as default shell

```sh
echo `which zsh` | sudo tee -a /etc/shells
chsh -s `which zsh`
```

## Windows

PowerShell 7 の [setup.ps1](./setup.ps1) でセットアップする。

- home-common と home-windows の配下のファイルを `%USERPROFILE%` にリンクする
- 改行コードは [.gitattributes](./.gitattributes) で LF に揃えている。CRLF になると、Claude Code が Git Bash で動かす hook が動かない

### SSH setting of GitHub

```pwsh
$p = "~/.ssh/keys/github"
mkdir -p $p
ssh-keygen -t ed25519 -f "$p/id_ed25519"
Get-Content "$p/id_ed25519.pub" | clip
# paste pub-key to GitHub -> Settings -> SSH and GPG keys -> SSH keys
```

### Clone this repo

```pwsh
# ~/.ssh/config は setup 後にリンクされるので、この時点では使う鍵を直接指定する
$env:GIT_SSH_COMMAND = "ssh -i ~/.ssh/keys/github/id_ed25519"
git clone git@github.com:guricerin/dotfiles.git ~/workspace/github.com/guricerin/dotfiles
Remove-Item Env:GIT_SSH_COMMAND
```

### Enable running `.ps1` scripts

```pwsh
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

Git で clone したファイルはローカルのスクリプトとして扱われるので、RemoteSigned で実行できる。

### Install tools

```pwsh
.\scripts\depends.ps1
```

winget・scoop・uv tool でツールを入れる。scoop は先に [公式の手順](https://scoop.sh/) で入れておく。

### Setup

シムリンクを作るには、「設定 → システム → 開発者向け」で開発者モードを有効にしておく。

```pwsh
.\setup.ps1 -DryRun   # 張るリンクを表示するだけ
.\setup.ps1           # 表示したあと、続けるかを聞く。聞かずに apply するときは -Yes
```

### Install Claude Code

```pwsh
irm https://claude.ai/install.ps1 | iex
```

hook と Bash ツールは Git Bash で動く。ghq の root は Mac・WSL2 と同じ `~/workspace` になる。

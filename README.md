# dotfiles

- [home ディレクトリ](./home/)配下のファイルを参照するシムリンクを、`$HOME`に再帰的に作成する
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

`depends.sh` で brew のツールと mise、uv tool のツールを入れてから、`mise install` で [~/.config/mise/config.toml](./home/.config/mise/config.toml) に書いたツールを入れる。`mise use --global` でツールを足すと、リンク先のこのリポジトリのファイルが書き換わるので、コミットする。

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

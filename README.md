# dotfiles

## Usage

```sh
cd $HOME
git clone https://github.com/guricerin/dotfiles.git
cd dotfiles/
bash setup.sh
```

## After setup

### Install linuxbrew

```sh
sudo apt install build-essential procps curl file git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- https://github.com/Homebrew/install
- https://docs.brew.sh/Homebrew-on-Linux#requirements

### Install tools

```sh
brew install zsh starship
```

### Set zsh as default shell

```sh
echo `which zsh` | sudo tee -a /etc/shells
chsh -s `which zsh`
```
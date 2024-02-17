# dotfiles

## Usage

### SSH setting of GitHub

```sh
ssh-keygen -t ed25519
cd ~/.ssh
mkdir github
mv id_25519* github/
cat github/id_25519.pub
# paste pub-key to GitHub -> Settings -> SSH and GPG keys -> SSH keys
```

### Setup

```sh
cd $HOME
git clone git@github.com:guricerin/dotfiles.git
cd dotfiles/
bash setup.sh
```

## After Setup

### Install linuxbrew

```sh
sudo apt install build-essential procps curl file git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- https://github.com/Homebrew/install
- https://docs.brew.sh/Homebrew-on-Linux#requirements

### Install tools

```sh
brew install zsh starship asdf pre-commit detect-secrets
```

### Set zsh as default shell

```sh
echo `which zsh` | sudo tee -a /etc/shells
chsh -s `which zsh`
```

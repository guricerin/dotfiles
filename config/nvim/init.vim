let $XDG_VIM_HOME = $HOME.'/.config/nvim'

set runtimepath+=$XDG_VIM_HOME

runtime! basic.vim
runtime! dein.vim

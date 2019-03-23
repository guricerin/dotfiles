" dein（プラグインマネージャ）をロード
let s:dein_dir = expand('~/.vim/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if &compatible
	set nocompatible
endif
" Add the dein installation directory into runtimepath
set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.vim/dein')
	call dein#begin('~/.vim/dein')

	call dein#add('~/.vim/dein/repos/github.com/Shougo/dein.vim')
	"call dein#add('Shougo/deoplete.nvim')
	"if !has('nvim')
	"  call dein#add('roxma/nvim-yarp')
	"  call dein#add('roxma/vim-hug-neovim-rpc')
	"endif
	call dein#add('cohama/lexima.vim')

	call dein#end()
	call dein#save_state()

	" 未インストールのプラグインがあればインストール
	if dein#check_install()
		call dein#install()
	endif
endif

filetype plugin indent on
syntax enable


" デフォルトでutf-8のはずだが、念のため
set encoding=utf-8

" 行番号を表示
set number

" シンタックスハイライトを有効化
"syntax enable
syntax on

" コメント文の色をグレイに
"hi Comment ctermfg=gray

" タイトル表示
set title

" カーソル位置を表示
set ruler

" 自動インデント
set autoindent
set smartindent

" タブ文字を表示する際の見た目上の幅
set tabstop=2

" タブキークリック時の幅
" 0ならtabstopと同じ値
set softtabstop=0

" インデント幅
set shiftwidth=2

" タブをスペースに変換
set noexpandtab

" バックスペースの動作：1文字消しつつ左に移動
set backspace=indent,eol,start
set mouse=a

colorscheme darkblue

set title

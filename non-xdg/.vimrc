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

" tabを入力したらspaceに変換
set expandtab
" タブ文字を表示する際の見た目上の幅
set tabstop=4
" タブキークリック時の幅
" 0ならtabstopと同じ値
set softtabstop=4
" インデント幅
set shiftwidth=4

" バックスペースの動作：1文字消しつつ左に移動
set backspace=indent,eol,start
set mouse=a

colorscheme darkblue

set title

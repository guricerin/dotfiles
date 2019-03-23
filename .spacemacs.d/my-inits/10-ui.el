;; -*- lexical-binding: t -*-

;; タイトルバーにファイルのフルパスを表示
(setq frame-title-format "%f")

;; 起動時にウィンドウを最大化
(set-frame-parameter nil 'fullscreen 'maximized)

;; 行番号とコードの間にスペースを入れる
(unless (display-graphic-p)
  (setq linum-format "%3s "))

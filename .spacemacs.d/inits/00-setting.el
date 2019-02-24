;; -*- lexical-binding: t -*-

;; 新しいリリースまでパッケージはstableを使う
(push '("melpa-stable" . "stable.melpa.org/packages/") configuration-layer--elpa-archives)
(push '(use-package . "melpa-stable") package-pinned-packages)

;; インデントにtab文字を使用しない
(setq-default indent-tabs-mode nil)

;; インデント幅は2文字分
(setq-default tab-width 2)

;; 括弧の対応
(smartparens-global-mode t)

;; シングルクオート挿入時に勝手にエスケープ文字を入れない。
(setq-default sp-escape-quotes-after-insert nil)

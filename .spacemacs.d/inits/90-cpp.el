;; -*- lexical-binding: t -*-

;; 処理系：clang C++14
(setq-default dotspacemacs-configuration-layers
              '((c-c++ :variables
                       c-c++-default-mode-for-headers 'c++-mode)))

(setq-default dotspacemacs-configuration-layers
              '((c-c++ :variables
                       c-c++-enable-clang-support t)))

;; (add-hook 'c++-mode-hook (lambda () (setq flycheck-clang-language-standard "c++14")))
(defun my-cpp-config ()
  (setq flycheck-clang-language-standard "c++14")
  (setq c-basic-offset 4)
  (setq-default tab-width 4))
(add-hook 'c++-mode-hook 'my-cpp-config)

(add-hook 'c++-mode-hook 'company-mode)

;;; clang-formatについて
;; cpp layer を導入していたらデフォルトで有効（ただし、aptなりbrewなりでclang-formatをインストールする必要あり）
;; SPC SPC clang-format で整形してくれる
;; .clang-format（設定ファイル）をプロジェクトなり$HOMEなりに置けば、再帰的に探しにいってくれる

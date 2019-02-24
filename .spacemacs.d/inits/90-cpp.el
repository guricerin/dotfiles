;; -*- lexical-binding: t -*-

;; 処理系：clang C++14
(setq-default dotspacemacs-configuration-layers
              '((c-c++ :variables
                       c-c++-default-mode-for-headers 'c++-mode)))
(add-hook 'c++-mode-hook (lambda () (setq flycheck-clang-language-standard "c++14")))


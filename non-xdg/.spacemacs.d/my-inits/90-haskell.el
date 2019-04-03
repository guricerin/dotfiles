;; -*- lexical-binding: t -*-

(custom-set-variables
 '(haskell-stylish-on-save t t))

(defun haskell-indentation-advice ()
  (when (and (< 1 (line-number-at-pos))
             (save-excursion
               (forward-line -1)
               (string= "" (s-trim (buffer-substring (line-beginning-position) (line-end-position))))))
    (delete-region (line-beginning-position) (point))))
(advice-add 'haskell-indentation-newline-and-indent
            :after 'haskell-indentation-advice)

(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)

;; hlint(Haskellの良いコード提案機能)を有効化
(add-hook 'haskell-mode-hook
          (lambda ()
            (setq flycheck-checker 'haskell-hlint)
            (flycheck-mode 1)))

(add-to-list 'exec-path "~/.local/bin/")

;; 保存時に自動でコードをフォーマット
(custom-set-variables '(haskell-stylish-on-save t))
;; (haskell-mode-stylish-buffer)

(setq
 ghc-ghc-options '("-fno-warn-missing-signatures")
 haskell-compile-cabal-build-command "cd %s && stack build"
 haskell-process-type 'stack-ghci
 haskell-interactive-popup-errors nil
 haskell-process-args-stack-ghci '("--ghc-options=-ferror-spans" "--with-ghc=ghci-ng")
 haskell-process-path-ghci "stack"
 )

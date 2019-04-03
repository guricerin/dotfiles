;; -*- lexical-binding: t -*-

;; lsp-mode
;; (use-package lsp-mode :commands lsp)
;; (use-package lsp-ui :commands lsp-ui-mode)
;; (use-package company-lsp :commands company-lsp)

;; (use-package ccls
;;   :hook ((c-mode c++-mode objc-mode) .
;;          (lambda () (require 'ccls) (lsp))))

(setq ccls-executable "~/ccls/Release/ccls")
;; ;; eglot
;; (use-package eglot
;;   :bind (:map eglot-mode-map
;;               ("C-c C-d" . eglot-help-at-point) ;; ポイント下の関数のドキュメントを表示
;;               ("C-c C-r" . eglot-code-actions) ;; もっと良いコードを提示
;;               )
;;   :hook
;;   ((c-mode-common . eglot-ensure))
;;   )
;; eglot
(use-package eglot
  :bind (:map eglot-mode-map
              ("C-c C-d" . eglot-help-at-point)
              ("C-c C-r" . eglot-code-actions)
              )
  :hook
  ((c-mode-common . eglot-ensure))
  )
(use-package company-lsp
  :after (eglot company)
  :defines company-backends
  :functions company-backends
  ;; :init (cl-pushnew (company-backend-with-yas 'company-lsp) company-backends)
  )

;; ccls(C++のlsp)

;; ;; cquery(C++のlsp)
;; ;; 要インストール
;; (defun cquery//enable ()
;;   (condition-case nil
;;       (lsp)
;;     (user-error nil)))
;; (use-package cquery
;;   :commands lsp
;;   :init (add-hook 'c-mode-hook #'cquery//enable)
;;   (add-hook 'c++-mode-hook #'cquery//enable))
;; ;; パスを通す
;; (setq cquery-executable "~/cquery/build")

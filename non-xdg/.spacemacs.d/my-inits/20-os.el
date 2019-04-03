;; -*- lexical-binding: t -*-

;; macの設定（GUI,CUIでのemacs起動を問わない）
(when (equal system-type 'darwin)
  ;; 「￥」を押下したら、代わりに「\」が表示される。
  (define-key evil-insert-state-map [165] [92]))

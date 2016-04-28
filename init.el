;;; init.el --- Initialization For this Org Pages Blog  -*- lexical-binding: t; -*-

(setq op/repository-directory "~/workbench/ziprandom.github.io/")   ;; the repository location
(setq op/site-domain "http://ziprandom.github.io/")         ;; your domain
(setq op/personal-github-link "http://github.com/ziprandom")
(setq op/site-main-title "random comments")
(setq op/site-sub-title "")
(setq op/theme "kd-mdo")         ;; theme
; set up my own theme since a sans option does not exist
(setq op/theme-root-directory "~/workbench/ziprandom.github.io/themes")
(setq op/theme 'emacs_real_love)  ; mdo is the default
;; sever easily with: python -m SimpleHTTPServer 9914

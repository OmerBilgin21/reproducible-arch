(setq gc-cons-threshold most-positive-fixnum)
(setq package-enable-at-startup nil)

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(internal-border-width . 0) default-frame-alist)

(setq frame-inhibit-implied-resize t)
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message user-login-name)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024))))

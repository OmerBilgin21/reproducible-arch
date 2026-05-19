;;; ============================================================
;;; Package setup
;;; ============================================================

(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa"  . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t)

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;;; ============================================================
;;; Sane defaults
;;; ============================================================

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 100)

(setq scroll-margin 4
      scroll-conservatively 101
      scroll-preserve-screen-position t
      mouse-wheel-scroll-amount '(3 ((shift) . 1))
      mouse-wheel-progressive-speed nil)

(setq confirm-kill-emacs #'yes-or-no-p
      create-lockfiles nil
      make-backup-files nil
      auto-save-default nil
      custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror))

(setq undo-limit 400000
      undo-strong-limit 600000
      undo-outer-limit 12000000)

(setq select-enable-clipboard t
      select-enable-primary nil)

(setq ring-bell-function #'ignore
      use-short-answers t
      delete-by-moving-to-trash t
      use-dialog-box nil)

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

(column-number-mode 1)
(global-font-lock-mode 1)
(global-hl-line-mode 1)
(delete-selection-mode 1)
(electric-pair-mode 1)
(global-auto-revert-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(save-place-mode 1)
(repeat-mode 1)
(which-key-mode 1)
(pixel-scroll-precision-mode 1)

(setq recentf-max-saved-items 200)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
(global-set-key (kbd "C-w") 'backward-kill-word)

;;; ============================================================
;;; Font & theme
;;; ============================================================

(set-face-attribute 'default nil
                    :font "CaskaydiaMono Nerd Font Mono"
                    :height 160)

(use-package doom-themes
  :config
  (load-theme 'doom-dracula t))

(set-frame-parameter nil 'alpha 97)
(add-to-list 'default-frame-alist '(alpha . 97))

;;; ============================================================
;;; Evil mode
;;; ============================================================

(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-undo-system 'undo-redo
        evil-shift-width 2)
  :config
  (evil-mode 1)

  (evil-set-leader 'normal (kbd "SPC"))
  (evil-set-leader 'visual (kbd "SPC"))

  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal)

  (evil-define-key 'normal 'global (kbd "C-d") (lambda () (interactive) (evil-scroll-down 15) (evil-scroll-line-to-center nil)))
  (evil-define-key 'normal 'global (kbd "C-u") (lambda () (interactive) (evil-scroll-up 15) (evil-scroll-line-to-center nil)))

  (evil-define-key '(normal visual) 'global (kbd "-") 'evil-end-of-line)
  (setq evil-kill-on-visual-paste nil
        evil-visual-update-x-selection-p nil)

  (evil-define-key 'normal 'global (kbd "M-j") (kbd ":m .+1 RET =="))
  (evil-define-key 'normal 'global (kbd "M-k") (kbd ":m .-2 RET =="))
  (evil-define-key 'visual 'global (kbd "M-j") (kbd ":m '>+1 RET gv=gv"))
  (evil-define-key 'visual 'global (kbd "M-k") (kbd ":m '<-2 RET gv=gv"))

  (evil-define-key 'normal 'global (kbd "<leader>bd") 'kill-current-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>SPC") 'project-switch-to-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bb") 'evil-switch-to-windows-last-buffer)

  (evil-define-key 'normal 'global (kbd "<leader>sh") 'evil-window-split)
  (evil-define-key 'normal 'global (kbd "<leader>sv") 'evil-window-vsplit)

  (evil-define-key '(insert normal) 'global (kbd "C-s") (lambda () (interactive) (evil-normal-state) (save-buffer)))

  (evil-define-key 'normal 'global (kbd "<leader>rm") (lambda () (interactive) (save-excursion (goto-char (point-min)) (while (search-forward "\r" nil t) (replace-match ""))))))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode 1))

;;; ============================================================
;;; Vertico + Orderless + Consult + Marginalia (Telescope)
;;; ============================================================

(use-package vertico
  :init (vertico-mode 1)
  :config
  (setq vertico-count 15
        vertico-cycle t))

(setq read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t
      completion-ignore-case t)

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-overrides '((file (styles basic partial-completion)))
        orderless-matching-styles '(orderless-literal orderless-regexp orderless-flex)))

(defun my/find-file ()
  (interactive)
  (let* ((default-directory (project-root (project-current t)))
         (files (split-string
                 (shell-command-to-string
                  "rg --files --hidden --no-ignore -g '!node_modules/' -g '!.git/' -g '!*lock.json' -g '!cdk.out/' -g '!dist/' -g '!build/' -g '!target/' -g '!venv/' -g '!*.next/' -g '!raycast/'")
                 "\n" t))
         (file (completing-read "Find file: " files nil t)))
    (find-file (expand-file-name file))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :config
  (setq consult-ripgrep-args
        "rg --null --line-buffered --color=never --max-columns=1000 --path-separator / --smart-case --no-heading --with-filename --line-number --search-zip --glob=!node_modules/ --glob=!.git/ --glob=!*lock.json --glob=!cdk.out/ --glob=!dist/ --glob=!build/ --glob=!target/")

  (evil-define-key 'normal 'global (kbd "C-p") 'my/find-file)
  (evil-define-key 'normal 'global (kbd "<leader>f") 'consult-ripgrep)
  (evil-define-key 'normal 'global (kbd "<leader>d") 'consult-info)
  (evil-define-key 'normal 'global (kbd "<leader>br") 'consult-git-grep)
  (evil-define-key 'normal 'global (kbd "<leader>xx") 'consult-flymake))

;;; ============================================================
;;; Corfu + Cape (completion)
;;; ============================================================

(use-package corfu
  :init (global-corfu-mode 1)
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.3
        corfu-auto-prefix 1
        corfu-cycle t
        corfu-preselect 'prompt
        corfu-count 20
        corfu-min-width 30
        corfu-max-width 80
        corfu-popupinfo-delay '(0.5 . 0.2))
  (corfu-popupinfo-mode 1)
  (add-to-list 'corfu--frame-parameters '(internal-border-width . 12))
  (custom-set-faces
   '(corfu-border ((t (:background "#ffffff"))))))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;;; ============================================================
;;; Eldoc-box (floating hover popups)
;;; ============================================================

(use-package eldoc-box)

;;; ============================================================
;;; Markdown rendering (used by eglot for hover docs)
;;; ============================================================

(use-package markdown-mode)

;;; ============================================================
;;; Eglot (LSP — builtin)
;;; ============================================================

(use-package eglot
  :ensure nil
  :hook ((typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure)
         (js-ts-mode . eglot-ensure)
         (go-ts-mode . eglot-ensure)
         (python-ts-mode . eglot-ensure)
         (bash-ts-mode . eglot-ensure)
         (lua-mode . eglot-ensure))
  :config
  (setq eglot-autoshutdown t
        eglot-events-buffer-size 0
        eglot-sync-connect nil)

  (setq-default eglot-workspace-configuration
                '(:vtsls (:autoUseWorkspaceTsdk t)
                         :typescript (:tsserver (:maxTsServerMemory 8192)
                                                :preferences (:includePackageJsonAutoImports "auto"))))

  (add-to-list 'eglot-ignored-server-capabilities :signatureHelpProvider)

  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (setq-local eldoc-documentation-strategy #'eldoc-documentation-compose)
              (setq-local eldoc-echo-area-use-multiline-p nil)))

  (add-to-list 'eglot-server-programs
               '((typescript-ts-mode tsx-ts-mode js-ts-mode)
                 . ("vtsls" "--stdio"
                    :initializationOptions
                    (:vtsls (:autoUseWorkspaceTsdk t)
                            :typescript (:tsserver (:maxTsServerMemory 8192)
                                                   :preferences (:includePackageJsonAutoImports "auto"))))))

  (put 'tsx-ts-mode 'eglot-language-id "typescriptreact")
  (put 'js-ts-mode 'eglot-language-id "javascript")
  (add-to-list 'eglot-server-programs
               '(go-ts-mode . ("gopls")))
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(bash-ts-mode . ("bash-language-server" "start")))
  (add-to-list 'eglot-server-programs
               '(lua-mode . ("lua-language-server")))

  (evil-define-key 'normal eglot-mode-map (kbd "K") 'eldoc-box-help-at-point)
  (evil-define-key 'normal eglot-mode-map (kbd "gd") 'xref-find-definitions)
  (evil-define-key 'normal eglot-mode-map (kbd "gr") 'xref-find-references)
  (evil-define-key 'normal eglot-mode-map (kbd "<leader>ca") 'eglot-code-actions)
  (evil-define-key 'normal eglot-mode-map (kbd "<leader>cr") 'eglot-rename))

;;; ============================================================
;;; Treesit (syntax highlighting — builtin)
;;; ============================================================

(use-package treesit-auto
  :config
  (setq treesit-auto-install 'prompt
        treesit-font-lock-level 4)
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))

;;; ============================================================
;;; Formatting (apheleia)
;;; ============================================================

(use-package apheleia
  :config
  (setf (alist-get 'prettier apheleia-formatters)
        '("prettier" "--stdin-filepath" filepath))
  (setf (alist-get 'gofmt apheleia-formatters)
        '("gofmt"))
  (setf (alist-get 'black apheleia-formatters)
        '("black" "-"))
  (setf (alist-get 'isort apheleia-formatters)
        '("isort" "-"))
  (setf (alist-get 'shfmt apheleia-formatters)
        '("shfmt" "-"))
  (setf (alist-get 'stylua apheleia-formatters)
        '("stylua" "-"))

  (defun my/apheleia-set-js-ts-formatters ()
    (setq-local apheleia-formatter
                (if (or (locate-dominating-file default-directory "biome.json")
                        (locate-dominating-file default-directory "biome.jsonc"))
                    '(biome)
                  '(prettier))))

  (dolist (hook '(typescript-ts-mode-hook tsx-ts-mode-hook js-ts-mode-hook json-ts-mode-hook))
    (add-hook hook #'my/apheleia-set-js-ts-formatters))
  (setf (alist-get 'go-ts-mode apheleia-mode-alist) '(gofmt))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(isort black))
  (setf (alist-get 'bash-ts-mode apheleia-mode-alist) '(shfmt))
  (setf (alist-get 'lua-mode apheleia-mode-alist) '(stylua))

  (apheleia-global-mode 1)

  (evil-define-key 'normal 'global (kbd "<leader>,")
    (lambda () (interactive) (apheleia-format-buffer (apheleia--get-formatters)))))

;;; ============================================================
;;; Git (magit)
;;; ============================================================

(use-package magit
  :config
  (evil-define-key 'normal 'global (kbd "<leader>gg") 'magit-status)
  (evil-define-key 'normal 'global (kbd "<leader>gb") 'magit-blame)
  (evil-define-key 'normal 'global (kbd "<leader>gl") 'magit-log-current)
  (evil-define-key 'normal 'global (kbd "<leader>gL") 'magit-log-all)
  (evil-define-key 'normal 'global (kbd "<leader>gd") 'magit-diff-dwim)
  (evil-define-key 'normal 'global (kbd "<leader>gp") 'magit-push)
  (evil-define-key 'normal 'global (kbd "<leader>gP") 'magit-pull)
  (evil-define-key 'normal 'global (kbd "<leader>gf") 'magit-fetch)
  (evil-define-key 'normal 'global (kbd "<leader>gS") 'magit-stash)
  (evil-define-key 'normal 'global (kbd "<leader>gc") 'magit-commit)
  (evil-define-key 'normal 'global (kbd "<leader>gC") 'magit-commit-amend)

  (defun my/magit-open-pr-url ()
    "Open GitHub PR creation page for the current branch."
    (interactive)
    (let* ((branch (magit-get-current-branch))
           (remote-url (magit-get "remote" "origin" "url"))
           (repo-url (replace-regexp-in-string
                      "\\(?:\\.git\\)?$" ""
                      (if (string-match "git@github\\.com:\\(.+\\)" remote-url)
                          (concat "https://github.com/" (match-string 1 remote-url))
                        remote-url))))
      (browse-url (format "%s/compare/%s?expand=1" repo-url branch))))

  (define-key magit-mode-map (kbd "C-c o") #'my/magit-open-pr-url))

;;; ============================================================
;;; Multi-project workspaces (tab-bar + project.el)
;;; ============================================================

(tab-bar-mode 1)
(setq tab-bar-show t
      tab-bar-new-tab-choice "*scratch*"
      tab-bar-close-button-show nil
      tab-bar-tab-hints t
      tab-bar-format '(tab-bar-format-tabs tab-bar-separator))

(defvar my/tab-project-roots (make-hash-table :test 'equal))

(defun my/project-try-tab-root (_dir)
  (when-let ((root (gethash (alist-get 'name (tab-bar--current-tab))
                            my/tab-project-roots)))
    (cons 'transient root)))

(add-hook 'project-find-functions #'my/project-try-tab-root nil nil)

(set-face-attribute 'tab-bar-tab nil
                    :background (face-attribute 'highlight :background nil t)
                    :foreground (face-attribute 'default :foreground nil t)
                    :weight 'bold
                    :box nil)
(set-face-attribute 'tab-bar-tab-inactive nil
                    :background (face-attribute 'tab-bar :background nil t)
                    :foreground (face-attribute 'shadow :foreground nil t)
                    :weight 'normal
                    :box nil)

(evil-define-key 'normal 'global (kbd "<leader>pp")
  (lambda () (interactive)
    (tab-bar-new-tab)
    (call-interactively #'dired)
    (let ((root (expand-file-name default-directory)))
      (tab-bar-rename-tab (file-name-nondirectory (directory-file-name root)))
      (puthash (alist-get 'name (tab-bar--current-tab)) root my/tab-project-roots))))

(evil-define-key 'normal 'global (kbd "<leader><tab><tab>") 'tab-bar-new-tab)
(evil-define-key 'normal 'global (kbd "<leader><tab><tab>") 'tab-bar-new-tab)
(evil-define-key 'normal 'global (kbd "<leader><tab>c") 'tab-bar-close-tab)
(evil-define-key 'normal 'global (kbd "S-<right>") 'tab-bar-switch-to-next-tab)
(evil-define-key 'normal 'global (kbd "<leader><tab>n") 'tab-bar-switch-to-next-tab)
(evil-define-key 'normal 'global (kbd "S-<left>") 'tab-bar-switch-to-prev-tab)
(evil-define-key 'normal 'global (kbd "<leader><tab>p") 'tab-bar-switch-to-prev-tab)

(define-prefix-command 'my/tab-prefix-map)
(evil-define-key '(normal visual motion insert) 'global (kbd "C-e") 'my/tab-prefix-map)
(define-key my/tab-prefix-map (kbd "1") (lambda () (interactive) (tab-bar-switch-to-prev-tab)))
(define-key my/tab-prefix-map (kbd "2") (lambda () (interactive) (tab-bar-select-tab 2)))
(define-key my/tab-prefix-map (kbd "3") (lambda () (interactive) (tab-bar-select-tab 3)))
(define-key my/tab-prefix-map (kbd "4") (lambda () (interactive) (tab-bar-select-tab 4)))
(define-key my/tab-prefix-map (kbd "5") (lambda () (interactive) (tab-bar-select-tab 5)))
(define-key my/tab-prefix-map (kbd "6") (lambda () (interactive) (tab-bar-select-tab 6)))
(define-key my/tab-prefix-map (kbd "7") (lambda () (interactive) (tab-bar-select-tab 7)))
(define-key my/tab-prefix-map (kbd "8") (lambda () (interactive) (tab-bar-select-tab 8)))
(define-key my/tab-prefix-map (kbd "9") (lambda () (interactive) (tab-bar-select-tab 9)))
(define-key my/tab-prefix-map (kbd "p") 'tab-bar-select-tab-by-name)

;;; ============================================================
;;; Terminal (vterm)
;;; ============================================================

(use-package vterm
  :config
  (setq vterm-max-scrollback 10000
        vterm-timer-delay 0.05)
  )

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el")
  :config
  (setq claude-code-ide-use-ide-diff nil)
  (claude-code-ide-emacs-tools-setup))

;;; ============================================================
;;; Avy (flash.nvim replacement)
;;; ============================================================

(use-package avy
  :config
  (evil-define-key '(normal visual operator) 'global (kbd "s") 'avy-goto-char-2))

;;; ============================================================
;;; Search & replace
;;; ============================================================

(evil-define-key 'normal 'global (kbd "<leader>sr") 'project-query-replace-regexp)

;;; ============================================================
;;; Diagnostics (flymake — builtin)
;;; ============================================================

;; (flymake-mode 1)

(setq flymake-no-changes-timeout 0.5)

(evil-define-key 'normal 'global (kbd "<leader>e")
  (lambda () (interactive)
    (dired (project-root (project-current t)))))

;;; ============================================================
;;; SQL (database client)
;;; ============================================================

(let ((sql-creds (expand-file-name "~/.sql-connections.el")))
  (when (file-exists-p sql-creds)
    (load sql-creds)))

(setq sql-postgres-login-params '(user database server port))


(defvar sql-last-prompt-pos 1
  "Position of last prompt when added recording started")
(make-variable-buffer-local 'sql-last-prompt-pos)
(put 'sql-last-prompt-pos 'permanent-local t)

(defun sql-add-newline-first (output)
  "Add newline to beginning of OUTPUT for `comint-preoutput-filter-functions'.
This fixes up the display of queries sent to the inferior buffer programatically."
  (let ((begin-of-prompt
         (or (and comint-last-prompt
                  (save-excursion
                    (goto-char (car comint-last-prompt))
                    (looking-at-p comint-prompt-regexp)
                    (point)))
             1)))
    (if (> begin-of-prompt sql-last-prompt-pos)
        (progn
          (setq sql-last-prompt-pos begin-of-prompt)
          (concat "\n" output))
      output)))

(add-hook 'sql-interactive-mode-hook
          (lambda ()
            (add-hook 'comint-preoutput-filter-functions 'sql-add-newline-first nil t)
            (setq truncate-lines t)
            (setq-local comint-buffer-maximum-size 10000)
            (setq-local comint-scroll-show-maximum-output nil)
            (setq-local scroll-conservatively 0)
            (setq-local redisplay-dont-pause nil)
            (when-let ((proc (get-buffer-process (current-buffer))))
              (set-process-window-size proc 50 10000))))


(defun my/sql-send-paragraph ()
  (interactive)
  (when-let ((buf (sql-find-sqli-buffer)))
    (with-current-buffer buf
      (comint-clear-buffer)))
  (sql-send-paragraph))

(add-hook 'sql-mode-hook
          (lambda ()
            (evil-local-set-key 'normal (kbd "C-f") 'my/sql-send-paragraph)))

(defun my/sql-connect-in-tab ()
  (interactive)
  (let* ((connection (completing-read "Connection: "
                                      (mapcar (lambda (c) (symbol-name (car c)))
                                              sql-connection-alist)))
         (tab-name (format "sql:%s" connection))
         (existing (seq-find (lambda (tab)
                               (string= tab-name (alist-get 'name tab)))
                             (tab-bar-tabs))))
    (if existing
        (tab-bar-select-tab-by-name tab-name)
      (tab-bar-new-tab)
      (tab-bar-rename-tab tab-name)
      (dired (expand-file-name "~/queries"))
      (let ((sql-display-sqli-buffer-function (lambda (buf)
                                                (evil-window-vsplit)
                                                (evil-window-right 1)
                                                (switch-to-buffer buf))))
        (sql-connect (intern connection))))))

(evil-define-key 'normal 'global (kbd "<leader><tab>d") 'my/db-workspace)

(use-package pg :vc (:url "https://github.com/emarsden/pg-el/") :demand t)

;; ============================================================
;; DB Browser
;; ============================================================

(defvar-local my/db-browser-con nil)
(defvar-local my/db-browser-expanded nil)
(defvar-local my/db-browser-cache nil)

(defun my/db-browser-uri (connection-name)
  (let ((p (cdr (assoc (intern connection-name) sql-connection-alist))))
    (format "postgresql://%s:%s@%s:%s/%s"
            (cadr (assoc 'sql-user p))
            (cadr (assoc 'sql-password p))
            (cadr (assoc 'sql-server p))
            (cadr (assoc 'sql-port p))
            (cadr (assoc 'sql-database p)))))

(defun my/db-browser--query (sql)
  (pg-result (pg-exec my/db-browser-con sql) :tuples))

(defun my/db-browser--schemas ()
  (or (gethash "schemas" my/db-browser-cache)
      (puthash "schemas"
               (mapcar #'car
                       (my/db-browser--query
                        "SELECT schema_name FROM information_schema.schemata
                          WHERE schema_name NOT IN ('pg_catalog','information_schema','pg_toast')
                          ORDER BY schema_name"))
               my/db-browser-cache)))

(defun my/db-browser--tables (schema)
  (let ((k (format "tables:%s" schema)))
    (or (gethash k my/db-browser-cache)
        (puthash k
                 (mapcar #'car
                         (my/db-browser--query
                          (format "SELECT table_name FROM information_schema.tables
                                    WHERE table_schema='%s' AND table_type='BASE TABLE'
                                    ORDER BY table_name" schema)))
                 my/db-browser-cache))))

(defun my/db-browser--columns (schema table)
  (let ((k (format "columns:%s.%s" schema table)))
    (or (gethash k my/db-browser-cache)
        (puthash k
                 (my/db-browser--query
                  (format "SELECT column_name, data_type, is_nullable, COALESCE(column_default,'')
                            FROM information_schema.columns
                            WHERE table_schema='%s' AND table_name='%s'
                            ORDER BY ordinal_position" schema table))
                 my/db-browser-cache))))

(defun my/db-browser--constraints (schema table)
  (let ((k (format "constraints:%s.%s" schema table)))
    (or (gethash k my/db-browser-cache)
        (puthash k
                 (my/db-browser--query
                  (format "SELECT c.conname,
                                    CASE c.contype
                                      WHEN 'c' THEN 'CHECK'
                                      WHEN 'f' THEN 'FK'
                                      WHEN 'p' THEN 'PK'
                                      WHEN 'u' THEN 'UNIQUE'
                                      WHEN 'x' THEN 'EXCL'
                                    END,
                                    pg_get_constraintdef(c.oid)
                             FROM pg_constraint c
                             JOIN pg_namespace n ON n.oid = c.connamespace
                             JOIN pg_class cl ON cl.oid = c.conrelid
                             WHERE n.nspname = '%s' AND cl.relname = '%s'
                             ORDER BY c.contype, c.conname" schema table))
                 my/db-browser-cache))))

(defun my/db-browser--insert-line (key text)
  (let ((start (point)))
    (insert text "\n")
    (when key
      (put-text-property start (1- (point)) 'my/db-browser-key key))))

(defun my/db-browser-render ()
  (let ((inhibit-read-only t)
        (saved-pos (point)))
    (erase-buffer)
    (dolist (schema (my/db-browser--schemas))
      (let* ((sk (format "schema:%s" schema))
             (s-open (gethash sk my/db-browser-expanded)))
        (my/db-browser--insert-line sk (format "%s %s" (if s-open "▼" "▶") schema))
        (when s-open
          (dolist (table (my/db-browser--tables schema))
            (let* ((tk (format "table:%s.%s" schema table))
                   (t-open (gethash tk my/db-browser-expanded)))
              (my/db-browser--insert-line tk (format "  %s %s" (if t-open "▼" "▶") table))
              (when t-open
                (let* ((ck (format "section:%s.%s.columns" schema table))
                       (c-open (gethash ck my/db-browser-expanded))
                       (xk (format "section:%s.%s.constraints" schema table))
                       (x-open (gethash xk my/db-browser-expanded)))
                  (my/db-browser--insert-line ck (format "    %s columns" (if c-open "▼" "▶")))
                  (when c-open
                    (dolist (col (my/db-browser--columns schema table))
                      (my/db-browser--insert-line nil
                                                  (concat "        "
                                                          (truncate-string-to-width (nth 0 col) 25 0 ?\s t) " "
                                                          (truncate-string-to-width (nth 1 col) 22 0 ?\s t) " "
                                                          (truncate-string-to-width (nth 2 col) 3  0 ?\s nil) " "
                                                          (nth 3 col)))))
                  (my/db-browser--insert-line xk (format "    %s constraints" (if x-open "▼" "▶")))
                  (when x-open
                    (dolist (con (my/db-browser--constraints schema table))
                      (my/db-browser--insert-line nil
                                                  (concat "        "
                                                          (truncate-string-to-width (nth 0 con) 30 0 ?\s t) " "
                                                          (truncate-string-to-width (nth 1 con) 7  0 ?\s nil) " "
                                                          (nth 2 con))))))))))))
    (goto-char (min saved-pos (point-max)))))

(defun my/db-browser-toggle ()
  (interactive)
  (when-let ((key (get-text-property (point) 'my/db-browser-key)))
    (puthash key (not (gethash key my/db-browser-expanded)) my/db-browser-expanded)
    (my/db-browser-render)))

(defun my/db-browser-refresh ()
  (interactive)
  (clrhash my/db-browser-cache)
  (my/db-browser-render))

(define-derived-mode my/db-browser-mode special-mode "DB-Browser"
  (setq-local my/db-browser-expanded (make-hash-table :test 'equal))
  (setq-local my/db-browser-cache (make-hash-table :test 'equal)))

(define-key my/db-browser-mode-map (kbd "RET") #'my/db-browser-toggle)
(define-key my/db-browser-mode-map (kbd "TAB") #'my/db-browser-toggle)
(define-key my/db-browser-mode-map (kbd "r") #'my/db-browser-refresh)

(evil-set-initial-state 'my/db-browser-mode 'motion)
(evil-define-key 'motion my/db-browser-mode-map
  (kbd "RET") #'my/db-browser-toggle
  (kbd "TAB") #'my/db-browser-toggle
  (kbd "C-h") #'evil-window-left
  (kbd "C-j") #'evil-window-down
  (kbd "C-k") #'evil-window-up
  (kbd "C-l") #'evil-window-right
  "j" #'next-line
  "k" #'previous-line
  "r" #'my/db-browser-refresh)

(defun my/db-browser (connection-name)
  (let ((buf (get-buffer-create (format "*db-browser:%s*" connection-name))))
    (with-current-buffer buf
      (my/db-browser-mode)
      (setq-local my/db-browser-con
                  (pg-connect/uri (my/db-browser-uri connection-name)))
      (my/db-browser-render))
    buf))

(defun my/db-workspace ()
  (interactive)
  (let* ((connection (completing-read "Connection: "
                                      (mapcar (lambda (c) (symbol-name (car c)))
                                              sql-connection-alist)))
         (tab-name (format "db:%s" connection))
         (existing (seq-find (lambda (tab)
                               (string= tab-name (alist-get 'name tab)))
                             (tab-bar-tabs))))
    (if existing
        (tab-bar-select-tab-by-name tab-name)
      (tab-bar-new-tab)
      (tab-bar-rename-tab tab-name)
      (let* ((p      (cdr (assoc (intern connection) sql-connection-alist)))
             (passwd (cadr (assoc 'sql-password p)))
             (process-environment (if passwd
                                      (cons (format "PGPASSWORD=%s" passwd)
                                            process-environment)
                                    process-environment))
             sqli-buf
             (sql-display-sqli-buffer-function
              (lambda (buf) (setq sqli-buf buf))))
        (sql-connect (intern connection))
        (let* ((browser-buf (my/db-browser connection))
               (dired-buf   (dired-noselect (expand-file-name "~/queries")))
               (w-right (progn (delete-other-windows) (selected-window)))
               (w-left  (split-window w-right 45 'left))
               (w-sqli  (split-window w-right nil 'below)))
          (set-window-buffer w-left  browser-buf)
          (set-window-buffer w-right dired-buf)
          (set-window-buffer w-sqli  sqli-buf)
          (select-window w-sqli))))))

;;; ============================================================
;;; Print debugger
;;; ============================================================

(defvar my/print-debug-config
  '((typescript-ts-mode :prefix "logger.info" :quote "'")
    (go-ts-mode         :prefix "internal.Logger" :spread t :quote "\"")))

(defun my/print-debug ()
  (interactive)
  (let* ((cfg (cdr (assq major-mode my/print-debug-config)))
         (prefix (plist-get cfg :prefix))
         (spread (plist-get cfg :spread))
         (q (or (plist-get cfg :quote) "'"))
         (var (thing-at-point 'symbol t))
         (indent (current-indentation)))
    (when (and var prefix)
      (delete-region (line-beginning-position) (line-end-position))
      (indent-to indent)
      (insert (if spread
                  (format "%s(%s%s%s, %s)" prefix q var q var)
                (format "%s(%s%s: %s, %s);" prefix q var q var))))))

;;; ============================================================
;;; Misc
;;; ============================================================

(setq-default tab-bar-auto-width nil)

(add-hook 'text-mode-hook
          (lambda ()
            (setq-local display-line-numbers nil)))

(define-key key-translation-map (kbd "C-c") (kbd "C-g"))
(define-key key-translation-map (kbd "C-g") (kbd "C-c"))

(defun my/vterm-shift-tab ()
  (interactive)
  (if (string-prefix-p "*claude-code[" (buffer-name))
      (vterm-send-string (concat "\e" "[Z"))
    (let* ((tab-name (alist-get 'name (tab-bar--current-tab)))
           (buf-name (format "*vterm[%s]*" tab-name))
           (buf (get-buffer buf-name)))
      (if (string-prefix-p buf-name (buffer-name))
          (evil-switch-to-windows-last-buffer)
        (if buf (switch-to-buffer buf) (vterm buf-name))))))

(defun my/smart-c-spc ()
  (interactive)
  (cond
   ((derived-mode-p 'vterm-mode)
    (claude-code-ide-toggle-window))
   ((evil-insert-state-p)
    (completion-at-point))
   ((evil-normal-state-p)
    (let ((process (claude-code-ide--get-process)))
      (if (and process (process-live-p process))
          (claude-code-ide-toggle-window)
        (claude-code-ide))))))

(with-eval-after-load 'vterm
  (with-eval-after-load 'evil
    (with-eval-after-load 'evil-collection

      (with-eval-after-load 'claude-code-ide
        (evil-define-key '(normal insert) 'global (kbd "C-SPC") 'my/smart-c-spc)
        (evil-define-key '(normal insert) vterm-mode-map (kbd "C-SPC") 'my/smart-c-spc)
        )

      (evil-define-key '(normal insert visual) 'global (kbd "<S-tab>") 'my/vterm-shift-tab)
      (evil-define-key '(normal insert visual) 'global (kbd "<backtab>") 'my/vterm-shift-tab) ;; this is backtab in linux and S-tab in mac -_-
      (evil-define-key '(normal insert) vterm-mode-map (kbd "C-e") 'my/tab-prefix-map)
      (evil-define-key '(normal insert) vterm-mode-map (kbd "<escape>") 'vterm-send-escape)
      (evil-define-key '(insert normal visual) vterm-mode-map (kbd "C-n") 'evil-normal-state)
      (evil-define-key '(insert normal visual) 'global (kbd "C-n") 'evil-normal-state)
      (evil-define-key 'insert 'global (kbd "C-g") 'evil-normal-state)
      (evil-define-key 'normal 'global (kbd "M-<up>") (lambda () (interactive) (enlarge-window 2)))
      (evil-define-key 'normal 'global (kbd "M-<down>") (lambda () (interactive) (shrink-window 2)))
      (evil-define-key 'normal 'global (kbd "M-<right>") (lambda () (interactive) (enlarge-window-horizontally 2)))
      (evil-define-key 'normal 'global (kbd "M-<left>") (lambda () (interactive) (shrink-window-horizontally 2)))
      (evil-define-key '(normal insert) 'global (kbd "C-h") 'evil-window-left)
      (evil-define-key '(normal insert) 'global (kbd "C-j") 'evil-window-down)
      (evil-define-key '(normal insert) 'global (kbd "C-k") 'evil-window-up)
      (evil-define-key '(normal insert) 'global (kbd "C-l") 'evil-window-right)
      (evil-define-key 'insert vterm-mode-map (kbd "C-c C-c") 'vterm--self-insert)
      (evil-define-key '(normal insert) 'global (kbd "C-f") 'my/print-debug)

      )))


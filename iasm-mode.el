;; -----------------------------------------------------------------------------
;; iasm-mode.el
;; Rémi Attab (remi.attab@gmail.com), 01 Jun 2013
;; FreeBSD-style copyright and disclaimer apply
;;
;; Interactive assembly mode for almighty emacs.
;;
;; The idea is grab the output of objdump, format it and make it interactive.
;; Let's hope it all works out.
;; -----------------------------------------------------------------------------


;; -----------------------------------------------------------------------------
;; Custom
;; -----------------------------------------------------------------------------

(defgroup iasm nil
  "Interactive assembly mode"
  :prefix "iasm-"
  :group 'tools)

(defcustom iasm-objdump "objdump"
  "Executable used to retrieve the assembly of an object file"
  :group 'iasm
  :type 'string)

(defcustom iasm-disasm-args "-dlCwj .text --no-show-raw-insn"
  "Arguments fed to the executable to retrieve assembly information"
  :group 'iasm
  :type 'string)


;; -----------------------------------------------------------------------------
;; Useful stuff
;; -----------------------------------------------------------------------------


(defun iasm-ctx-at-point ()
  (interactive)
  (message (format "Context: %s:%s"
		   (get-text-property (point) 'iasm-ctx-file)
		   (get-text-property (point) 'iasm-ctx-line))))


(define-derived-mode iasm-mode asm-mode
  "iasm"
  "BLAH!
\\{iasm-mode-map}"
  :group 'iasm
  (toggle-truncate-lines t)
  (beginning-of-buffer)

  (local-set-key (kbd "S") 'iasm-ctx-at-point))

(defun iasm-buffer-name (file)
  (concat "*iasm " (file-name-nondirectory file) "*"))


(defun iasm-disasm-args (file)
  (cons (expand-file-name file) (split-string iasm-disasm-args " ")))

(defun iasm-set-current-ctx (line)
  (let ((split (split-string (match-string 1 line) ":")))
    (setq iasm-current-ctx-file (car split))
    (setq iasm-current-ctx-line (car (cdr split)))))

(defun iasm-insert (line)
  (insert line)
  (newline))

(defun iasm-insert-header (line)
  (iasm-insert "")
  (iasm-insert line))

(defun iasm-insert-inst (line)
  (let ((first (point)))
    (iasm-insert-line line)
    (add-text-properties first (point) `(iasm-ctx-file ,iasm-current-ctx-file))
    (add-text-properties first (point) `(iasm-ctx-line ,iasm-current-ctx-line))))

(defconst iasm-parse-table
  '(("^\\([/a-zA-Z0-9\\._-]*:[0-9]*\\)" . iasm-set-current-ctx)
    ("^[0-9a-f]* <\\([a-zA-Z0-9_-]*\\)>:$" . iasm-insert-header)
    ("^ *[0-9a-f]*:" . iasm-insert-inst)))

(defun iasm-parse-line (line)
  (dolist (pair iasm-parse-table)
    (save-match-data
      (when (string-match (car pair) line)
	(apply (cdr pair) line '())))))

(defun iasm-exec (buf args)
  "The world's most inneficient way to process the output of a process."
  (let ((lines (apply 'process-lines iasm-objdump args)))
    (with-current-buffer buf
      (setq iasm-current-context nil)
      (make-variable-buffer-local 'iasm-current-context)
      (dolist (line lines)
	(iasm-parse-line line)))))

(defun iasm-disasm (file)
  (interactive "fObject file: ")
  (let ((buf (get-buffer-create (iasm-buffer-name file)))
	(args (iasm-disasm-args file)))
    (with-current-buffer buf (erase-buffer))

    (message (format "Running: %s %s" iasm-objdump args))
    (iasm-exec buf args)

    (switch-to-buffer-other-window buf)
    (with-current-buffer buf (iasm-mode))))

(provide 'iasm-mode)

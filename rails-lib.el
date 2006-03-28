;;; rails-lib.el ---

;; Copyright (C) 2006 Galinsky Dmitry <dima dot exe at gmail dot com>

;; Authors: Galinsky Dmitry <dima dot exe at gmail dot com>,
;;          Rezikov Peter <crazypit13 (at) gmail.com>
;; Keywords: ruby rails languages oop
;; $URL$
;; $Id$

;;; License

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

;;; Code:

(defun rails-lib:goto-file-with-menu (dir title &optional ext no-inflector)
  "Make menu to choose files and find-file it"
  (let* (file
         files
         (ext (if ext ext "rb"))
         (ext (concat "\\." ext "$"))
         (root (rails-core:root))
         (dir (concat root dir))
         (mouse-coord (if (functionp 'posn-at-point) ; mouse position at point
                         (nth 2 (posn-at-point))
                       (cons 200 100))))
    (message dir)
    (message ext)
    (message files)
    (setq files (find-recursive-directory-relative-files dir "" ext))
    (setq files (sort files 'string<))
    (setq files (reverse files))
    (setq files (mapcar
                 (lambda(f)
                   (cons (if no-inflector
                             f
                           (rails-core:class-by-file f)) f))
                 files))
    (setq file (x-popup-menu
                (list (list (car mouse-coord) (cdr mouse-coord)) (selected-window))
                (list title (cons title files ))))
    (if file
        (find-file (concat dir file)))))

(defun rails-lib:goto-controllers ()
  "Goto Controller"
  (interactive)
  (rails-lib:goto-file-with-menu "app/controllers/" "Go to controller.."))

(defun rails-lib:goto-models ()
  "Goto Model"
  (interactive)
  (rails-lib:goto-file-with-menu "app/models/" "Go to model.."))

(defun rails-lib:goto-helpers ()
  "Goto helper"
  (interactive)
  (rails-lib:goto-file-with-menu "app/helpers/" "Go to helper.."))

(defun rails-lib:goto-layouts ()
  "Goto layout"
  (interactive)
  (rails-lib:goto-file-with-menu "app/views/layouts/" "Go to layout.." "rhtml" t))

(defun rails-lib:goto-stylesheets ()
  "Goto layout"
  (interactive)
  (rails-lib:goto-file-with-menu "public/stylesheets/" "Go to stylesheet.." "css" t))

(defun rails-lib:goto-javascripts ()
  "Goto layout"
  (interactive)
  (rails-lib:goto-file-with-menu "public/javascripts/" "Go to stylesheet.." "js" t))

(defun rails-lib:goto-migrate ()
  "Goto layout"
  (interactive)
  (rails-lib:goto-file-with-menu "db/migrate/" "Go to migrate.." "rb" t))

(defun rails-lib:run-primary-switch ()
  (interactive)
  (if rails-primary-switch-func
      (apply rails-primary-switch-func nil)))

(defun rails-lib:run-secondary-switch ()
  (interactive)
  (if rails-primary-switch-func
      (apply rails-secondary-switch-func nil)))

;;;;; Non Rails realted helper functions ;;;;;

;; Syntax macro

(defmacro* when-bind ((var expr) &rest body)
  "Binds ``var'' and result of ``expr''.
   If ``expr'' is not nil do body.
   (when-bind (var (func foo))
      (do-somth (with var)))"
  `(let ((,var ,expr))
     (when ,var
       ,@body)))

;; Lists

(defun list->alist (list)
  "Convert (a b c) to ((a . a) (b . b) (c . c))"
  (mapcar #'(lambda (el) (cons el el))
    list))

(defun uniq-list (list)
  "Retrurn list of uniq elements"
  (let ((result '()))
    (dolist (elem list)
      (when (not (member elem result))
  (push elem result)))
    (nreverse result)))

;; Strings

(defun string-not-empty (str) ;(+)
  "Return t if string ``str'' not empty"
  (and (stringp str) (not (string-equal str ""))))

(defun yml-next-value (name)
  "Return value of next parameter with name"
  (search-forward-regexp (format "%s:[ ]*\\(.*\\)[ ]*$" name))
  (match-string 1))

(defun current-line-string ()
  "Return string value of current line"
  (buffer-substring-no-properties
   (progn (beginning-of-line) (point))
   (progn (end-of-line) (point))))

(defun remove-postfix (word postfix)
  "Remove postifix in word if exits.
  BlaPostfix -> Bla"
  (replace-regexp-in-string (format "%s$" postfix) "" word))

(defun strings-join (separator strings)
  "Join all STRINGS with SEPARATOR"
  (let ((new-string
   (apply #'concat
    (mapcar (lambda (str) (concat str separator))
      strings))))
  (subseq new-string 0 (- (length new-string) (length separator)))))


;;;;;;;; def-snips stuff ;;;;

(defun snippet-abbrev-function-name (abbrev-table abbrev-name)
  "Return name of snips abbrev function in abbrev-table for abbrev abbrev-name"
  (intern (concat "snippet-abbrev-"
      (snippet-strip-abbrev-table-suffix
       (symbol-name abbrev-table))
      "-"
      abbrev-name)))

(defun snippet-menu-description-variable (table name)
  "Return variable for menu description of snip abbrev-name in abbrev-table"
  (intern
   (concat
    (symbol-name (snippet-abbrev-function-name table name))
    "-menu-description")))

(defmacro* def-snips ((&rest abbrev-tables) &rest snips)
  "Generate snippets with menu documentaion in several ``abbrev-tables''
  (def-snip (some-mode-abbrev-table other-mode-abbrev-table)
    (\"abbr\"   \"some snip $${foo}\" \"menu documentation\")
    (\"anabr\"   \"other snip $${bar}\" \"menu documentation\")
"
  `(progn
     ,@(loop for table in abbrev-tables
       collect
       `(snippet-with-abbrev-table ',table
    ,@(loop for (name template desc) in snips collect
      `(,name . ,template)))
       append
       (loop for (name template desc) in snips collect
       `(setf ,(snippet-menu-description-variable table name)
       ,desc)))))

(defun snippet-menu-description (abbrev-table name)
  "Return menu descripton for snip in ``abbrev-table'' with name ``name''"
  (symbol-value (snippet-menu-description-variable abbrev-table name)))

(defun snippet-menu-line (abbrev-table name)
  "Generate menu line for snip ``name''"
  (cons
   (snippet-menu-description abbrev-table name)
   (snippet-abbrev-function-name abbrev-table name)))

;;; Define keys

(defmacro define-keys (key-map &rest key-funcs)
  "Define key bindings for key-map (create key-map, if does not exist"
  `(progn
     (unless (boundp ',key-map)
       (setf ,key-map (make-keymap)))
     ,@(mapcar
  #'(lambda (key-func)
      `(define-key ,key-map ,(first key-func) ,(second key-func)))
  key-funcs)))

;; Files

(defun append-string-to-file (file string)
  "Append string to end of file"
  (write-region string nil file t))

;; File hierarchy functions

(defun find-recursive-files (file-regexp directory)
  "Return list of files, founded in directory, than match file-regexp"
  (find-recursive-filter-out
   find-recursive-exclude-files
   (find-recursive-directory-relative-files directory "" file-regexp)))

(defun directory-name (path)
  "Return name of directory with path
  f.e. path /foo/bar/baz/../, return bar
  "
  ;; Rewrite me
  (let ((old-path default-directory))
    (cd path)
    (let ((dir (pwd)))
      (cd old-path)
      (replace-regexp-in-string "^Directory[ ]*" "" dir))))

(defun find-or-ask-to-create (question file)
    "Open file  if exist. If not exist ask to create it."
    (if (file-exists-p file)
  (find-file file)
      (when (y-or-n-p question)
  (when (string-match "\\(.*\\)/[^/]+$" file)
    (make-directory (match-string 1 file) t))
  (find-file file))))

(defun directory-of-file (file-name)
  "Return parent directory of file FILE-NAME"
  (replace-regexp-in-string "[^/]*$" "" file-name))

;; Buffers

(defun buffer-string-by-name (buffer-name)
  "Return content of buffer buffer-name as string"
  (interactive)
  (save-excursion
    (set-buffer buffer-name)
    (buffer-string)))

(provide 'rails-lib)
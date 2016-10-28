;;; helm-projectile-open-with.el ---

;; Copyright (C) 2016 Launay Gaby

;; Author: Launay Gaby <gaby.launay@gmail.com>
;; Maintainer: Launay Gaby <gaby.launay@gmail.com>
;; Version: 0.1.0
;; Keywords: helm, projectile, open
;; URL: http://github.com/muahah/helm-projectile-open-with

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'helm)
(require 'projectile)

(defvar helm-projectile-open-with--file-list ())

(defcustom helm-projectile-open-with-associations
  '(("inkscape" . ("\\.svg" "\\.eps" "\\.pdf"))
    ("gimp" . ("\\.png" "\\.jpg" "\\.jpeg")))
  "Associations between softwares and file extensions"
  :type '(alist :key-type (string) :value-type (repeat regexp))
  :group 'helm-projectile-open-with)

(defvar helm-projectile-open-with--source
  (helm-build-sync-source "Projectile open with"
    :candidates (lambda () helm-projectile-open-with--file-list)
    :fuzzy-match helm-projectile-fuzzy-match
    :keymap helm-find-files-map
    :mode-line helm-read-file-name-mode-line-string
    :action '(("Open with associated software" . helm-projectile-open-with--open-file)
	      ("Open in Emacs" . find-file)))
  "Helm source for opening projectile files with different softwares")

(defun helm-projectile-open-with--get-editing-software (filename)
  "Return the software associated to the given filename "
  (loop for (soft . exts) in helm-projectile-open-with-associations do
	(setq soft (loop for ext in exts do
			 (setq ext (format "%s$" ext))
			 (when (string-match ext filename)
			   (return soft))))
	(when soft
	  (return soft))))

(defun helm-projectile-open-with--get-files ()
  "Return a list of project files associated to a software"
  (let ((proj-files (projectile-current-project-files))
	(proj-images ()))
    (loop for file in proj-files do
	  (when (helm-projectile-open-with--get-editing-software file)
	    (setq proj-images (cons file proj-images))))
    (if (= (length proj-images) 0)
      (error "[%s] No file with associated software in this project" (projectile-project-name))
    proj-images)))

(defun helm-projectile-open-with--open-file (file)
  "Open a file with the associated software"
  (let ((soft (helm-projectile-open-with--get-editing-software file)))
    (message "Open \"%s\" with %s" file (capitalize soft))
    (call-process soft nil 0 nil file)))

(defun helm-projectile-open-with ()
  "Select a project file and open it with the associated software"
  (interactive)
  (setq helm-projectile-open-with--file-list (helm-projectile-open-with--get-files))
  (helm :sources helm-projectile-open-with--source
	:buffer "*helm-projectile-open-with*"
	:nomark t
	:prompt "Find file: "))

(provide 'helm-projectile-open-with)

;;; misc.el --- some nonstandard editing and utility commands for Emacs  -*- lexical-binding:t -*-

;; Copyright (C) 1989, 2001-2022 Free Software Foundation, Inc.

;; Maintainer: emacs-devel@gnu.org
;; Keywords: convenience
;; Package: emacs

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'tabulated-list))

;;;###autoload
(defun copy-from-above-command (&optional arg)
  "Copy characters from previous nonblank line, starting just above point.
Copy ARG characters, but not past the end of that line.
If no argument given, copy the entire rest of the line.
The characters copied are inserted in the buffer before point.

Also see the `duplicate-line' command."
  (interactive "P")
  (let ((cc (current-column))
	n
	(string ""))
    (save-excursion
      (beginning-of-line)
      (backward-char 1)
      (skip-chars-backward " \t\n")
      (move-to-column cc)
      ;; Default is enough to copy the whole rest of the line.
      (setq n (if arg (prefix-numeric-value arg) (point-max)))
      ;; If current column winds up in middle of a tab,
      ;; copy appropriate number of "virtual" space chars.
      (if (< cc (current-column))
	  (if (= (preceding-char) ?\t)
	      (progn
		(setq string (make-string (min n (- (current-column) cc)) ?\s))
		(setq n (- n (min n (- (current-column) cc)))))
	    ;; In middle of ctl char => copy that whole char.
	    (backward-char 1)))
      (setq string (concat string
			   (buffer-substring
			    (point)
			    (min (line-end-position)
				 (+ n (point)))))))
    (insert string)))

;;;###autoload
(defun duplicate-line (&optional n)
  "Duplicate the current line N times.
Interactively, N is the prefix numeric argument, and defaults to 1.
Also see the `copy-from-above-command' command."
  (interactive "p")
  (unless n
    (setq n 1))
  (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
    (save-excursion
      (forward-line 1)
      (unless (bolp)
        (insert "\n"))
      (dotimes (_ n)
        (insert line "\n")))))

;; Variation of `zap-to-char'.

;;;###autoload
(defun zap-up-to-char (arg char &optional interactive)
  "Kill up to, but not including ARGth occurrence of CHAR.
When run interactively, the argument INTERACTIVE is non-nil.
Case is ignored if `case-fold-search' is non-nil in the current buffer.
Goes backward if ARG is negative; error if CHAR not found.
Ignores CHAR at point.
If called interactively, do a case sensitive search if CHAR
is an upper-case character."
  (interactive (list (prefix-numeric-value current-prefix-arg)
		     (read-char-from-minibuffer "Zap up to char: "
						nil 'read-char-history)
                     t))
  (let ((direction (if (>= arg 0) 1 -1))
        (case-fold-search (if (and interactive (char-uppercase-p char))
                              nil
                            case-fold-search)))
    (kill-region (point)
		 (progn
		   (forward-char direction)
		   (unwind-protect
		       (search-forward (char-to-string char) nil nil arg)
		     (backward-char direction))
		   (point)))))

;; These were added with an eye to making possible a more CCA-compatible
;; command set; but that turned out not to be interesting.

;;;###autoload
(defun mark-beginning-of-buffer ()
  "Set mark at the beginning of the buffer."
  (interactive)
  (push-mark (point-min)))

;;;###autoload
(defun mark-end-of-buffer ()
  "Set mark at the end of the buffer."
  (interactive)
  (push-mark (point-max)))

;;;###autoload
(defun upcase-char (arg)
  "Uppercasify ARG chars starting from point.  Point doesn't move."
  (interactive "p")
  (save-excursion
    (upcase-region (point) (progn (forward-char arg) (point)))))

;;;###autoload
(defun forward-to-word (arg)
  "Move forward until encountering the beginning of a word.
With argument, do this that many times."
  (interactive "^p")
  (or (re-search-forward (if (> arg 0) "\\W\\b" "\\b\\W") nil t arg)
      (goto-char (if (> arg 0) (point-max) (point-min)))))

;;;###autoload
(defun backward-to-word (arg)
  "Move backward until encountering the end of a word.
With argument, do this that many times."
  (interactive "^p")
  (forward-to-word (- arg)))

;;;###autoload
(defun butterfly ()
  "Use butterflies to flip the desired bit on the drive platter.
Open hands and let the delicate wings flap once.  The disturbance
ripples outward, changing the flow of the eddy currents in the
upper atmosphere.  These cause momentary pockets of higher-pressure
air to form, which act as lenses that deflect incoming cosmic rays,
focusing them to strike the drive platter and flip the desired bit.
You can type `M-x butterfly C-M-c' to run it.  This is a permuted
variation of `C-x M-c M-butterfly' from url `https://xkcd.com/378/'."
  (interactive)
  (if (yes-or-no-p "Do you really want to unleash the powers of the butterfly? ")
      (progn
	(switch-to-buffer (get-buffer-create "*butterfly*"))
	(erase-buffer)
	(sit-for 0)
	(animate-string "Amazing physics going on..."
			(/ (window-height) 2) (- (/ (window-width) 2) 12))
	(sit-for (* 5 (/ (abs (random)) (float most-positive-fixnum))))
	(message "Successfully flipped one bit!"))
    (message "Well, then go to xkcd.com!")
    (browse-url "https://xkcd.com/378/")))

;; A command to list dynamically loaded libraries.  This useful in
;; environments where dynamic-library-alist is used, i.e., Windows

(defvar list-dynamic-libraries--loaded-only-p)
(make-variable-buffer-local 'list-dynamic-libraries--loaded-only-p)

(defun list-dynamic-libraries--loaded (from)
  "Compute the \"Loaded from\" column.
Internal use only."
  (if from
      (let ((name (car from))
            (path (or (cdr from) "<unknown>")))
        ;; This is a roundabout way to change the tooltip without
        ;; having to replace the default printer function
        (propertize name
                    'display (propertize name
                                         'help-echo (concat "Loaded from: " path))))
    ""))

(defun list-dynamic-libraries--refresh ()
  "Recompute the list of dynamic libraries.
Internal use only."
  (setq tabulated-list-format  ; recomputed because column widths can change
        (let ((max-id-len 7) (max-name-len 11))
          (dolist (lib dynamic-library-alist)
            (let ((id-len (length (symbol-name (car lib))))
                  (name-len (apply 'max (mapcar 'length (cdr lib)))))
              (when (> id-len max-id-len) (setq max-id-len id-len))
              (when (> name-len max-name-len) (setq max-name-len name-len))))
          (vector (list "Library" (1+ max-id-len) t)
                  (list "Loaded from" (1+ max-name-len) t)
                  (list "Candidate names" 0 t))))
  (tabulated-list-init-header)
  (setq tabulated-list-entries nil)
  (dolist (lib dynamic-library-alist)
    (let* ((id (car lib))
           (from (get id :loaded-from)))
      (when (or from
                (not list-dynamic-libraries--loaded-only-p))
        (push (list id (vector (symbol-name id)
                               (list-dynamic-libraries--loaded from)
                               (mapconcat 'identity (cdr lib) ", ")))
              tabulated-list-entries))))
  (when (not dynamic-library-alist)
    (message "No dynamic libraries found")))

;;;###autoload
(defun list-dynamic-libraries (&optional loaded-only-p buffer)
  "Display a list of all dynamic libraries known to Emacs.
\(These are the libraries listed in `dynamic-library-alist'.)
If optional argument LOADED-ONLY-P (interactively, prefix arg)
is non-nil, only libraries already loaded are listed.
Optional argument BUFFER specifies a buffer to use, instead of
\"*Dynamic Libraries*\".
The return value is always nil."
  (interactive "P")
  (unless (bufferp buffer)
    (setq buffer (get-buffer-create "*Dynamic Libraries*")))
  (with-current-buffer buffer
    (tabulated-list-mode)
    (setq tabulated-list-sort-key (cons "Library" nil))
    (add-hook 'tabulated-list-revert-hook 'list-dynamic-libraries--refresh nil t)
    (setq list-dynamic-libraries--loaded-only-p loaded-only-p)
    (list-dynamic-libraries--refresh)
    (tabulated-list-print))
  (display-buffer buffer)
  nil)

(provide 'misc)

;;; misc.el ends here

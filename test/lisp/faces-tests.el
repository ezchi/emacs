;;; faces-tests.el --- Tests for faces.el            -*- lexical-binding: t; -*-

;; Copyright (C) 2013-2019 Free Software Foundation, Inc.

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(require 'ert)
(require 'faces)

(defgroup faces--test nil ""
  :group 'faces--test)

(defface faces--test1
  '((t :background "black" :foreground "black"))
  ""
  :group 'faces--test)

(defface faces--test2
  '((t :box 1))
  ""
  :group 'faces--test)

(defface faces--test-extend
  '((t :extend t :background "blue"))
  ""
  :group 'faces--test)

(defface faces--test-no-extend
  '((t :extend nil :background "blue"))
  ""
  :group 'faces--test)

(defface faces--test-inherit-extend
  '((t :inherit (faces--test-extend faces--test2) :background "blue"))
  ""
  :group 'faces--test)

(defface faces--test-inherit-no-extend
  '((t :inherit (faces--test2 faces--test-no-extend) :background "blue"))
  ""
  :group 'faces--test)

(ert-deftest faces--test-color-at-point ()
  (with-temp-buffer
    (insert (propertize "STRING" 'face '(faces--test2 faces--test1)))
    (goto-char (point-min))
    (should (equal (background-color-at-point) "black"))
    (should (equal (foreground-color-at-point) "black")))
  (with-temp-buffer
    (insert (propertize "STRING" 'face '(:foreground "black" :background "black")))
    (goto-char (point-min))
    (should (equal (background-color-at-point) "black"))
    (should (equal (foreground-color-at-point) "black")))
  (with-temp-buffer
    (emacs-lisp-mode)
    (setq-local font-lock-comment-face 'faces--test1)
    (setq-local font-lock-constant-face 'faces--test2)
    (insert ";; `symbol'")
    (font-lock-fontify-region (point-min) (point-max))
    (goto-char (point-min))
    (should (equal (background-color-at-point) "black"))
    (should (equal (foreground-color-at-point) "black"))
    (goto-char 6)
    (should (equal (background-color-at-point) "black"))
    (should (equal (foreground-color-at-point) "black"))))

(ert-deftest faces--test-face-id ()
  ;; Face ID of 0 is the 'default' face; no face should have the same ID.
  (should (> (face-id 'faces--test1) 0))
  ;; 'tooltip' is the last face defined by preloaded packages, so any
  ;; face we define in Emacs should have a face ID greater than that,
  ;; since the ID of a face is just its index in the array that maps
  ;; face IDs to faces.
  (should (> (face-id 'faces--test1) (face-id 'tooltip))))

(ert-deftest faces--test-extend ()
  (should (equal (face-attribute 'faces--test-extend :extend) t))
  (should (equal (face-attribute 'faces--test-no-extend :extend) nil))
  (should (equal (face-attribute 'faces--test1 :extend) 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-extend :extend nil t) t))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend nil t)
                 nil))
  )

(ert-deftest faces--test-extend-with-themes ()
  ;; Make sure the diff-mode faces are not defined.
  (should-not (featurep 'diff-mode))
  (defface diff-changed-face
    '((t :extend t :weight bold))
    "")
  (defface diff-added
    '((t :background "grey"))
    "")
  (defface diff-file-header-face
    '((t :extend nil :foreground "cyan"))
    "")
  (should (equal (face-attribute 'diff-changed-face :extend) t))
  (should (equal (face-attribute 'diff-added :extend) 'unspecified))
  (should (equal (face-attribute 'diff-file-header-face :extend) nil))
  (load-theme 'manoj-dark t t)
  (load-theme 'tsdh-light t t)
  (should (equal (face-attribute 'faces--test-inherit-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-extend :extend nil t) t))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend nil t)
                 nil))
  (should (equal (face-attribute 'diff-changed-face :extend) t))
  (should (equal (face-attribute 'diff-added :extend) 'unspecified))
  (should (equal (face-attribute 'diff-file-header-face :extend) nil))
  (enable-theme 'manoj-dark)
  (should (equal (face-attribute 'faces--test-inherit-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-extend :extend nil t) t))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend nil t)
                 nil))
  (should (equal (face-attribute 'diff-changed-face :extend) 'unspecified)) ; should be t
  (should (equal (face-attribute 'diff-added :extend) t))
  (should (equal (face-attribute 'diff-file-header-face :extend) 'unspecified)) ; should be nil
  (defface faces--test-face3
    '((t :inherit diff-added :weight bold))
    "")
  (should (equal (face-attribute 'faces--test-face3 :extend nil t) t))
  (disable-theme 'manoj-dark)
  (should (equal (face-attribute 'faces--test-inherit-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-extend :extend nil t) t))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend nil t)
                 nil))
  (should (equal (face-attribute 'diff-changed-face :extend) t))
  (should (equal (face-attribute 'diff-added :extend) 'unspecified))
  (should (equal (face-attribute 'diff-file-header-face :extend) nil))
  (should (equal (face-attribute 'faces--test-face3 :extend nil t) 'unspecified))
  (defface diff-indicator-changed
    '((t (:weight bold :extend t)))
    "")
  (enable-theme 'tsdh-light)
  (should (equal (face-attribute 'faces--test-inherit-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-extend :extend nil t) t))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend nil t)
                 nil))
  (should (equal (face-attribute 'diff-changed-face :extend) t))
  (should (equal (face-attribute 'diff-added :extend) t))
  (should (equal (face-attribute 'diff-file-header-face :extend) nil))
  (should (equal (face-attribute 'diff-indicator-changed :extend) 'unspecified)) ; should be t
  (should (equal (face-attribute 'faces--test-face3 :extend nil t) t))
  (frame-set-background-mode (selected-frame) 'dark)
  (should (equal (face-attribute 'faces--test-inherit-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-extend :extend nil t) t))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend)
                 'unspecified))
  (should (equal (face-attribute 'faces--test-inherit-no-extend :extend nil t)
                 nil))
  (should (equal (face-attribute 'diff-changed-face :extend) t))
  (should (equal (face-attribute 'diff-added :extend) t))
  (should (equal (face-attribute 'diff-file-header-face :extend) nil))
  (should (equal (face-attribute 'diff-indicator-changed :extend) 'unspecified)) ; should be t
  (should (equal (face-attribute 'faces--test-face3 :extend nil t) t))
  (or noninteractive
      (let ((fr (make-frame)))
        (should (equal (face-attribute 'faces--test-inherit-extend :extend fr)
                       'unspecified))
        (should (equal (face-attribute 'faces--test-inherit-extend :extend fr t)
                       t))
        (should (equal (face-attribute 'faces--test-inherit-no-extend
                                       :extend fr)
                       'unspecified))
        (should (equal (face-attribute 'faces--test-inherit-no-extend
                                       :extend fr t)
                       nil))
        (should (equal (face-attribute 'diff-changed-face :extend fr) t))
        (should (equal (face-attribute 'diff-added :extend fr) t))
        (should (equal (face-attribute 'diff-file-header-face :extend fr) nil))
        (should (equal (face-attribute 'diff-indicator-changed :extend fr)
                       'unspecified)) ; should be t
        (should (equal (face-attribute 'faces--test-face3 :extend nil t) t))
        ))
  (disable-theme 'tsdh-light)
  (should (equal (face-attribute 'diff-indicator-changed :extend) t))
  (should (equal (face-attribute 'faces--test-face3 :extend nil t) 'unspecified))
  (or noninteractive
      (let ((fr (make-frame)))
        (should (equal (face-attribute 'diff-changed-face :extend fr) t))
        (should (equal (face-attribute 'diff-added :extend fr) 'unspecified))
        (should (equal (face-attribute 'diff-file-header-face :extend fr) nil))
        (should (equal (face-attribute 'diff-indicator-changed :extend fr) t))
        (should (equal (face-attribute 'faces--test-face3 :extend nil t) 'unspecified))
        ))
  )

(provide 'faces-tests)
;;; faces-tests.el ends here

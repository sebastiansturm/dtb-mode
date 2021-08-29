;;; dtb-mode.el --- Show device tree souce in dtbs -*- lexical-binding: t -*-

;; Copyright (C) 2020 Schspa Shi

;; Author: Schspa Shi <schspa@gmail.com>
;; URL: https://github.com/schspa/dtb-mode
;; Package-Requires: ((emacs "25"))
;; Version: 20210102.2003
;; Keywords: dtb dts convenience

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Toggle `dtb-mode' to show the symbols that the binary uses instead
;; of the actual binary contents.
;;
;; References:
;;    https://en.wikipedia.org/wiki/Device_tree
;;    https://github.com/abo-abo/elf-mode

;;; Code:

(defgroup dtb nil
  "Minor mode for viewing dtb files."
  :group 'languages)

(defcustom dtb-dtc-executable-path
  "dtc"
  "The location of the dtc executable."
  :type 'string
  :group 'dtb)

(defun dtb--translate (orig-file-name)
  (if (file-remote-p orig-file-name)
      (let ((tmp-path (make-temp-file (file-name-nondirectory orig-file-name)))
            (result))
        (copy-file orig-file-name tmp-path t)
        (with-temp-buffer
          (find-file tmp-path)
          (setq result
                (shell-command-to-string
                 (format "%s -I dtb %s"
                         dtb-dtc-executable-path
                         (shell-quote-argument tmp-path)))))
        (delete-file tmp-path)
        result)
    ;; local file, process directly
    (shell-command-to-string
     (format "%s -I dtb %s"
             dtb-dtc-executable-path
             (shell-quote-argument orig-file-name)))))

(define-minor-mode dtb-mode
  "Minor-mode for viewing device tree blobs."
  nil " dtb" nil
  (let* ((inhibit-read-only t)
         (file-name (buffer-file-name))
         (dtc_bin (executable-find dtb-dtc-executable-path)))
    (cond
     ((not file-name) (message "No file association with current buffer"))
     ((not dtc_bin) (message "Can't find dtc executable"))
     (t (progn
          (if dtb-mode
              (let ((translated-contents (dtb--translate file-name)))
                (erase-buffer)
                (insert translated-contents)
                (goto-char (point-min))
                (if (fboundp 'dts-mode) (dts-mode)))
            (erase-buffer)
            (insert-file-contents file-name))
          (read-only-mode +1)
          (set-buffer-modified-p nil))))))

;;;###autoload
(add-to-list 'magic-mode-alist '("^\320\015\376\355" . dtb-mode))

(provide 'dtb-mode)
;;; dtb-mode.el ends here

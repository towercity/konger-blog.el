;;; konger-blog.el --- Functions to mess with my blog

;;; Commentary:
;;; Very basic, unformed script.

;;; Code:
(require 'obsidian)

(defvar konger-blog-obsidian-dir)
(defvar konger-blog-media-dir)
(defvar konger-blog-book-dir)

(setq konger-blog-obsidian-dir "~/Documents/Writing"
      konger-blog-media-dir (concat konger-blog-obsidian-dir "/media")
      konger-blog-book-dir (concat konger-blog-media-dir "/book")
      )

;; unfinsihed: only gets the hash for books
;; atm this is like... USELESS. its HELLA SLOW. can we speed this process up
;; somehow, perhaps by caching after run once???
(defun konger-blog-get-books ()
  "Return a list of items marked as books in Obsidian."
  (let* ((book-files (directory-files konger-blog-book-dir
                                      t directory-files-no-dot-files-regexp))
         (book-hash (mapcar #'obsidian--file-front-matter book-files))
         )
    (message (gethash 'tags (car book-hash)))
    ))

(defun konger-blog-make-book-block (&rest args)
  "Create a block element for a book, with details in ARGS."
  (let* ((cover-img (plist-get args :cover))
         (title (plist-get args :title))
         (author (plist-get args :author))
         (start-date (plist-get args :start-date))
         (comment (plist-get args :comment))
         (book-html (konger-blog-make-block (format
                                             "<div class='cover'>
    <img src='%s' alt='cover-img'>
  </div>
  <div class='info'>
    <h3><strong>%s</strong> by <strong>%s</strong></h3>
    <div class='logbook'>
      <strong>started:</strong>
      %s
    </div>
    <div class='comment'>
      %s
    </div>
  </div>" cover-img title author start-date comment) :class "book-block")))
    book-html))

(defun konger-blog-make-block (content &rest args)
  "Create a block element, with settings in ARGS."
  (let* ((class (string-join (flatten-list (push "block" (plist-get args :class)))
                             " ")))
    (format "<div class='%s'>%s</div>"
            class content)))

(provide 'konger-blog)

;;; konger-blog.el ends here

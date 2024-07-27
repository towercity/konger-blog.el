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

(defun konger-blog-get-book-block-from-file (file &rest args)
  "Create a book block from FILE, with settings ARGS."
  (interactive "fWhich file: ")
  (let* ((book-hash (obsidian--file-front-matter file)))
    ;; make sure we have a book before we go, ok
    (if (seq-contains-p (gethash 'tags book-hash) "book")
        (konger-blog-make-book-block :cover (gethash 'cover book-hash)
                                     :title (gethash 'title book-hash)
                                     :author (gethash 'author book-hash)
                                     :start-date (gethash 'start-date book-hash)
                                     :styles? (plist-get args :styles?))
      (user-error "%s" "Not a book note"))))

(defun konger-blog-make-book-block (&rest args)
  "Create a block element for a book, with details in ARGS."
  (let* ((cover-img (or (plist-get args :cover) ""))
         (title (or (plist-get args :title) ""))
         (author (or (plist-get args :author) ""))
         (start-date (or (plist-get args :start-date) ""))
         (comment (or (plist-get args :comment) ""))
         (styles (if (plist-get args :styles?)
                     (konger-blog-get-style-tag) "")))
        (konger-blog-make-block (format
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
  </div>%s" cover-img title author start-date comment styles) :class "book-block")))

(defun konger-blog-make-block (content &rest args)
  "Create a block element containg CONTENT, with settings in ARGS."
  (let* ((class (string-join (flatten-list (push "block" (plist-get args :class)))
                             " ")))
    (format "<div class='%s'>%s</div>"
            class content)))

(defun konger-blog-get-style-tag ()
  "Return the content of the local style.css file, wrapped in a <style> tag."
  (format "<style>%s</style>"
          (f-read "~/.emacs.d/my-packages/konger-blog/style.css")))

(provide 'konger-blog)

;;; konger-blog.el ends here

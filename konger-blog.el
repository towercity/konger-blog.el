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
      konger-blog-book-dir (concat konger-blog-media-dir "/book"))

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

;; TODO: pull in date, content
;; TODO: how to do multiple reads? likely we'll need to do some workarounds
(defun konger-blog-get-book-block-from-file (file &rest args)
  "Create a book block from FILE, with settings ARGS."
  (interactive "fWhich file: ")
  (let* ((book-hash (obsidian--file-front-matter file))
         (logbook (or (gethash 'logbook book-hash) [])))
    ;; make sure we have a book before we go, ok
    (if (seq-contains-p (gethash 'tags book-hash) "book")
        (konger-blog-make-book-block
         :cover (gethash 'cover book-hash)
         :title (gethash 'title book-hash)
         :author (konger-blog-combine-array-commas-or-and
                  (mapcar #'konger-blog-handle-obsidian-links
                          (gethash 'author book-hash)))
         :date (konger-blog-get-book-date-markup
                (seq-elt logbook
                         (or (plist-get args :read-number)
                             (- (length logbook) 1))))
         :styles? (or (plist-get args :styles?) t)
         :comment (or (plist-get args :comment)
                      (konger-blog-handle-obsidian-links
                       (konger-blog-get-review-text file))))
      (user-error "%s" "Not a book note"))))

(defun konger-blog-make-book-block (&rest args)
  "Create a block element for a book, with details in ARGS."
  (let* ((cover-img (or (plist-get args :cover) ""))
         (title (or (plist-get args :title) ""))
         (author (or (plist-get args :author) ""))
         (date (or (plist-get args :date) ""))
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
      %s
    </div>
    <div class='comment'>
      %s
    </div>
  </div>%s" cover-img title author date comment styles) :class "book-block")
))

(defun konger-blog-get-book-date-markup (date)
  "Get the html markup for logbook item DATE."
  (let* ((dates-list (split-string date " - " t)))
    (cl-case (length dates-list)
      (1 (format "<strong>started: </strong>%s" (pop dates-list)))
      (2 (format "<strong>read: </strong>%s through %s"
                 (pop dates-list) (pop dates-list)))
      (t ""))))

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

(defun konger-blog-combine-array-commas-or-and (array)
  "Combine array ARRAY into a string.
Will use either the word \"and\" or commas, depending on number of items in array."
  (if (arrayp array)
      (cl-case (length array)
        (0 "")
        (1 (aref array 0))
        (2 (string-join array " and "))
        (t (string-join array ",")))
    (car array)))

(defun konger-blog-handle-obsidian-links (string)
  "Handle the obsidian link syntax in STRING."
  ;; TODO: do some actual work here, lol. atm, just strips
  (replace-regexp-in-string "\\[\\[\\|\\]\\]" "" string))

(defun konger-blog-get-book-block (bookname)
  "Get book block BOOKNAME.
Presumed to be held in the correct media file, and already a bookfile."
  (let ((bookfile (concat konger-blog-book-dir "/" bookname ".md")))
    (konger-blog-get-book-block-from-file bookfile)))

(defun konger-blog-get-book-for-cohost (bookname)
  "Get the book block for BOOKNAME for cohost."
  (shell-command-to-string (format "echo \"%s\" | %s"
                                   (konger-blog-get-book-block bookname)
                                   "~/.cargo/bin/css-inline")))

(defun konger-blog-get-review-text (file)
  "Gather the review text from book note FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (let* ((rev-regex "# rev")
           (review-start (progn
                           (re-search-forward rev-regex)
                           (forward-line)
                           (point)))
           (review-end (progn
                         (outline-next-heading)
                         (point))))
      (buffer-substring review-start review-end))))

(provide 'konger-blog)

;;; konger-blog.el ends here

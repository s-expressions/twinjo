;; SPDX-FileCopyrightText: 2019 Lassi Kortela
;; SPDX-License-Identifier: ISC

(define (read-char? char)
  (and (eqv? char (peek-char))
       (read-char)))

(define (read-char-satisyfing predicate)
  (and (predicate (peek-char))
       (read-char)))

(define (read-char* first-char? subsequent-char?)
  (let ((first-char (read-char-satisyfing first-char?)))
    (and first-char
         (let loop ((chars (list first-char)))
           (let ((char (read-char-satisyfing subsequent-char?)))
             (if (not char)
                 (list->string (reverse chars))
                 (loop (cons char chars))))))))

(define (skip-rest-of-line)
  (unless (or (read-char? (eof-object)) (read-char? #\newline))
    (read-char)
    (skip-rest-of-line)))

(define (twinjo-whitespace-char? obj)
  (case obj ((#\space #\tab #\newline #\return #\,) #t) (else #f)))

(define (skip-whitespace-and-comments)
  (cond ((read-char-satisyfing twinjo-whitespace-char?)
         (skip-whitespace-and-comments))
        ((read-char? #\;)
         (skip-rest-of-line)
         (skip-whitespace-and-comments))))

(define (terminate? what sentinel)
  (skip-whitespace-and-comments)
  (if (read-char? (eof-object))
      (error (string-append "Unterminated " what))
      (not (not (read-char? sentinel)))))

(define (read-list)
  (let loop ((elts '()))
    (if (terminate? "list" #\))
        (reverse elts)
        (loop (cons (must-read-one "list element") elts)))))

(define (read-mapping)
  (let loop ((pairs '()))
    (if (terminate? "mapping" #\})
        (alist->hash-table (reverse pairs))
        (let ((key (must-read-one "mapping key")))
          (skip-whitespace-and-comments)
          (let ((val (must-read-one "mapping value")))
            (loop (cons (cons key val) pairs)))))))

(define (symbol-first? char)
  (and (char? char) (char-alphabetic? char)))

(define (symbol-subsequent? char)
  (and (char? char) (or (char-alphabetic? char)
                        (char-numeric? char)
                        (case char ((#\- #\_) #t) (else #f)))))

(define (read-bare-symbol?)
  (let ((name (read-char* symbol-first? symbol-subsequent?)))
    (and name (string->symbol name))))

(define (read-sharpsign)
  (if (read-char? #\{)
      (read-mapping)
      (case (read-bare-symbol?)
        ((t) #t)
        ((f) #f)
        ((#f) (error "Unknown character after sharpsign"))
        (else (error "Unknown symbol after sharpsign")))))

(define (read-char-escape)
  (or (read-char? #\\)
      (read-char? #\")
      (read-char? #\|)
      (error "Unknown escape character")))

(define (read-quoted-stringlike what sentinel)
  (let loop ((chars '()))
    (cond ((read-char? (eof-object))
           (error (string-append "Unterminated " what)))
          ((read-char? sentinel)
           (list->string (reverse chars)))
          ((read-char? #\\)
           (loop (cons (read-char-escape) chars)))
          (else
           (loop (cons (read-char) chars))))))

(define (read-quoted-string)
  (read-quoted-stringlike "double-quoted string" #\"))

(define (read-quoted-symbol)
  (string->symbol (read-quoted-stringlike "vertical-bar symbol" #\|)))

(define (read-number?)
  (let* ((sign (read-char? #\-))
         (magnitude (read-char* char-numeric? char-numeric?)))
    (if (not magnitude)
        (and sign (error "Sign without magnitude"))
        (let ((magnitude (string->number magnitude)))
          (if sign (- magnitude) magnitude)))))

(define (read-bare-symbol-or-number)
  (or (read-bare-symbol?)
      (read-number?)))

(define (may-read-one)
  (cond ((read-char? #\()
         (read-list))
        ((read-char? #\#)
         (read-sharpsign))
        ((read-char? #\")
         (read-quoted-string))
        ((read-char? #\|)
         (read-quoted-symbol))
        (else
         (or (read-bare-symbol-or-number)
             (or (read-char? (eof-object))
                 (error (string-append "Unknown syntax character in input: "
                                       (string (read-char)))))))))

(define (must-read-one what)
  (let ((one (may-read-one)))
    (if (eof-object? one)
        (error (string-append "Expected " what))
        one)))

(define (twinjo-text-read)
  (skip-whitespace-and-comments)
  (may-read-one))

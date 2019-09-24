;; SPDX-FileCopyrightText: 2019 Lassi Kortela
;; SPDX-License-Identifier: ISC

(define-library (core binary write)
  (export core-binary-write)
  (import (scheme base)
          (scheme char)
          (scheme write)
          (srfi 69)
          (srfi 151))
  (include "write.scm"))

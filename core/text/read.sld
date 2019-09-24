;; SPDX-FileCopyrightText: 2019 Lassi Kortela
;; SPDX-License-Identifier: ISC

(define-library (core text read)
  (export core-text-read)
  (import (scheme base)
          (scheme char)
          (scheme read)
          (srfi 69))
  (include "read.scm"))

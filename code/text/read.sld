;; SPDX-FileCopyrightText: 2019 Lassi Kortela
;; SPDX-License-Identifier: ISC

(define-library (twinjo text read)
  (export twinjo-text-read)
  (import (scheme base)
          (scheme char)
          (scheme read)
          (srfi 69))
  (include "read.scm"))

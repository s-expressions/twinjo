;; SPDX-FileCopyrightText: 2019 Lassi Kortela
;; SPDX-License-Identifier: ISC

(define-library (twinjo text write)
  (export twinjo-text-write)
  (import (scheme base)
          (scheme char)
          (scheme write)
          (srfi 69))
  (include "write.scm"))

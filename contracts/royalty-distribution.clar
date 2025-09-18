;; RoyaltyDistribution Contract
(define-constant ERR_NOT_OWNER u100)
(define-constant ERR_ALREADY_INITIALIZED u101)
(define-constant ERR_NOT_INITIALIZED u102)
(define-constant ERR_INVALID_SHARE u103)
(define-constant ERR_NO_RECIPIENTS u104)
(define-constant ERR_STX_TRANSFER u105)
(define-constant ERR_FT_TRANSFER u106)
(define-constant ERR_ZERO_AMOUNT u107)

(define-constant ZERO_PRINCIPAL 'SP000000000000000000002Q6VF78)

(define-data-var owner principal ZERO_PRINCIPAL)
(define-data-var recipient-count uint u0)
(define-data-var total-shares uint u0)
(define-map recipients {idx: uint} {addr: principal, share: uint})

(define-read-only (is-owner)
  (is-eq tx-sender (var-get owner)))

(define-public (init-owner)
  (begin
    (asserts! (is-eq (var-get owner) ZERO_PRINCIPAL) (err ERR_ALREADY_INITIALIZED))
    (var-set owner tx-sender)
    (ok true)))

(define-public (add-recipient (r principal) (share uint))
  (let ((idx u0))
    (ok (map-insert recipients {idx: idx} {addr: r, share: share}))))

(define-public (update-recipient (idx uint) (new-addr principal) (new-share uint))
  (begin
    (asserts! (is-owner) (err ERR_NOT_OWNER))
    (asserts! (and (>= new-share u0) (<= new-share u100)) (err ERR_INVALID_SHARE))
    (asserts! (< idx (var-get recipient-count)) (err ERR_NO_RECIPIENTS))
    (match (map-get? recipients {idx: idx})
      recipient
      (ok (var-set total-shares (- (+ (var-get total-shares) new-share) (get share recipient))))
      (err u201))))

(define-public (remove-recipient (idx uint))
  (begin
    (asserts! (is-owner) (err ERR_NOT_OWNER))
    (asserts! (< idx (var-get recipient-count)) (err ERR_NO_RECIPIENTS))
    (match (map-get? recipients {idx: idx})
      recipient
      (begin
        (map-delete recipients {idx: idx})
        (var-set recipient-count (- (var-get recipient-count) u1))
        (var-set total-shares (- (var-get total-shares) (get share recipient)))
        (ok true))
      (err u202))))

(define-read-only (get-recipient (idx uint))
  (map-get? recipients {idx: idx}))

(define-read-only (get-recipient-count)
  (var-get recipient-count))

(define-read-only (get-total-shares)
  (var-get total-shares))

(define-private (compute-share-amount (amount uint) (rshare uint) (tot uint))
  (let ((condition (or (is-eq tot u0) (is-eq amount u0))))
    (if condition
      u0
      (/ (* amount rshare) tot))))

(define-public (distribute-stx (amount uint))
  (if (and (> amount u0) (> (var-get total-shares) u0))
    (let ((recipient (map-get? recipients {idx: u0})))
      (match recipient
        r (ok (stx-transfer? amount tx-sender (get addr r)))
        (err ERR_NO_RECIPIENTS)))
    (err ERR_ZERO_AMOUNT)))

(define-public (distribute-ft (token-contract principal) (amount uint))
  (ok amount))

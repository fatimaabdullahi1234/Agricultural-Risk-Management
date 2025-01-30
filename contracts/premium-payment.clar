;; Premium Payment Contract

(define-map premium-payments
  { payment-id: uint }
  {
    policy-id: uint,
    amount: uint,
    paid-at: uint
  }
)

(define-map policy-payments
  { policy-id: uint }
  { payment-ids: (list 100 uint) }
)

(define-data-var payment-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))

(define-read-only (get-premium-payment (payment-id uint))
  (map-get? premium-payments { payment-id: payment-id })
)

(define-read-only (get-policy-payments (policy-id uint))
  (map-get? policy-payments { policy-id: policy-id })
)

(define-public (make-premium-payment (policy-id uint) (amount uint))
  (let
    ((new-payment-id (+ (var-get payment-id-nonce) u1))
     (policy-payment-list (default-to { payment-ids: (list) } (map-get? policy-payments { policy-id: policy-id }))))
    (map-set premium-payments
      { payment-id: new-payment-id }
      {
        policy-id: policy-id,
        amount: amount,
        paid-at: block-height
      }
    )
    (map-set policy-payments
      { policy-id: policy-id }
      { payment-ids: (unwrap! (as-max-len? (append (get payment-ids policy-payment-list) new-payment-id) u100) ERR_UNAUTHORIZED) }
    )
    (var-set payment-id-nonce new-payment-id)
    (ok new-payment-id)
  )
)

(define-read-only (is-premium-paid (policy-id uint))
  (match (get-policy-payments policy-id)
    payments (> (len (get payment-ids payments)) u0)
    false
  )
)

(define-read-only (get-total-premiums-paid (policy-id uint))
  (match (get-policy-payments policy-id)
    payments (fold + (map get-payment-amount (get payment-ids payments)) u0)
    u0
  )
)

(define-private (get-payment-amount (payment-id uint))
  (default-to u0 (get amount (get-premium-payment payment-id)))
)


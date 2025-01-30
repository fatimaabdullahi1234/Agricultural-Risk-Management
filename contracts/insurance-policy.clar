;; Insurance Policy Management Contract

(define-map policies
  { policy-id: uint }
  {
    farmer: principal,
    crop-type: (string-ascii 64),
    coverage-amount: uint,
    premium-amount: uint,
    start-date: uint,
    end-date: uint,
    location: (string-ascii 128),
    status: (string-ascii 20)
  }
)

(define-map farmer-policies
  { farmer: principal }
  { policy-ids: (list 100 uint) }
)

(define-data-var policy-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_STATUS (err u400))

(define-read-only (get-policy (policy-id uint))
  (map-get? policies { policy-id: policy-id })
)

(define-read-only (get-farmer-policies (farmer principal))
  (map-get? farmer-policies { farmer: farmer })
)

(define-public (create-policy (crop-type (string-ascii 64)) (coverage-amount uint) (premium-amount uint) (start-date uint) (end-date uint) (location (string-ascii 128)))
  (let
    ((new-policy-id (+ (var-get policy-id-nonce) u1))
     (farmer-policy-list (default-to { policy-ids: (list) } (map-get? farmer-policies { farmer: tx-sender }))))
    (map-set policies
      { policy-id: new-policy-id }
      {
        farmer: tx-sender,
        crop-type: crop-type,
        coverage-amount: coverage-amount,
        premium-amount: premium-amount,
        start-date: start-date,
        end-date: end-date,
        location: location,
        status: "active"
      }
    )
    (map-set farmer-policies
      { farmer: tx-sender }
      { policy-ids: (unwrap! (as-max-len? (append (get policy-ids farmer-policy-list) new-policy-id) u100) ERR_UNAUTHORIZED) }
    )
    (var-set policy-id-nonce new-policy-id)
    (ok new-policy-id)
  )
)

(define-public (cancel-policy (policy-id uint))
  (let
    ((policy (unwrap! (map-get? policies { policy-id: policy-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get farmer policy) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status policy) "active") ERR_INVALID_STATUS)
    (ok (map-set policies
      { policy-id: policy-id }
      (merge policy { status: "cancelled" })
    ))
  )
)

(define-public (expire-policy (policy-id uint))
  (let
    ((policy (unwrap! (map-get? policies { policy-id: policy-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status policy) "active") ERR_INVALID_STATUS)
    (ok (map-set policies
      { policy-id: policy-id }
      (merge policy { status: "expired" })
    ))
  )
)

(define-read-only (is-policy-active (policy-id uint))
  (match (map-get? policies { policy-id: policy-id })
    policy (is-eq (get status policy) "active")
    false
  )
)


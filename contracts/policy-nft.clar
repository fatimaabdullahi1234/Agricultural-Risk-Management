;; Policy NFT Contract

(define-non-fungible-token policy-nft uint)

(define-map policy-nft-data
  { token-id: uint }
  {
    policy-id: uint,
    farmer: principal,
    metadata: (string-utf8 256)
  }
)

(define-data-var token-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))

(define-read-only (get-last-token-id)
  (ok (var-get token-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
  (ok none)
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? policy-nft token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
    (nft-transfer? policy-nft token-id sender recipient)
  )
)

(define-public (mint-policy-nft (policy-id uint) (metadata (string-utf8 256)))
  (let
    ((new-token-id (+ (var-get token-id-nonce) u1))
     (policy (unwrap! (contract-call? .insurance-policy get-policy policy-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get farmer policy)) ERR_UNAUTHORIZED)
    (asserts! (is-none (nft-get-owner? policy-nft new-token-id)) ERR_ALREADY_EXISTS)
    (try! (nft-mint? policy-nft new-token-id tx-sender))
    (map-set policy-nft-data
      { token-id: new-token-id }
      {
        policy-id: policy-id,
        farmer: tx-sender,
        metadata: metadata
      }
    )
    (var-set token-id-nonce new-token-id)
    (ok new-token-id)
  )
)

(define-read-only (get-policy-nft-data (token-id uint))
  (map-get? policy-nft-data { token-id: token-id })
)


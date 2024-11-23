;; Content License Manager Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-licensed (err u101))
(define-constant err-not-licensed (err u102))
(define-constant err-invalid-price (err u103))

;; Data Maps
(define-map licenses 
    { content-id: uint, licensee: principal }
    { expires: uint, license-type: (string-ascii 10) }
)

(define-map content-registry
    { content-id: uint }
    { 
        owner: principal,
        price: uint,
        license-type: (string-ascii 10)
    }
)

;; Data Variables
(define-data-var next-content-id uint u1)

;; Register new content
(define-public (register-content (price uint) (license-type (string-ascii 10)))
    (let ((content-id (var-get next-content-id)))
        (map-set content-registry
            { content-id: content-id }
            { 
                owner: tx-sender,
                price: price,
                license-type: license-type
            }
        )
        (var-set next-content-id (+ content-id u1))
        (ok content-id)
    )
)

;; Purchase license
(define-public (purchase-license (content-id uint))
    (let (
        (content (unwrap! (map-get? content-registry { content-id: content-id }) (err u404)))
        (existing-license (map-get? licenses { content-id: content-id, licensee: tx-sender }))
    )
        (asserts! (is-none existing-license) err-already-licensed)
        (try! (stx-transfer? (get price content) tx-sender (get owner content)))
        (map-set licenses
            { content-id: content-id, licensee: tx-sender }
            { 
                expires: (+ block-height u52560), ;; License valid for ~1 year
                license-type: (get license-type content)
            }
        )
        (ok true)
    )
)

;; Check if address has valid license
(define-read-only (has-valid-license (content-id uint) (address principal))
    (match (map-get? licenses { content-id: content-id, licensee: address })
        license (ok (< block-height (get expires license)))
        (err err-not-licensed)
    )
)

;; Get content details
(define-read-only (get-content-details (content-id uint))
    (ok (map-get? content-registry { content-id: content-id }))
)

;; Update content price - owner only
(define-public (update-price (content-id uint) (new-price uint))
    (let ((content (unwrap! (map-get? content-registry { content-id: content-id }) (err u404))))
        (asserts! (is-eq tx-sender (get owner content)) err-owner-only)
        (asserts! (> new-price u0) err-invalid-price)
        (map-set content-registry
            { content-id: content-id }
            (merge content { price: new-price })
        )
        (ok true)
    )
)

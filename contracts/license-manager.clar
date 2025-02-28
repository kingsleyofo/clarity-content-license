;; Content License Manager Contract
;; Enhanced version with additional security and functionality

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-licensed (err u101))
(define-constant err-not-licensed (err u102))
(define-constant err-invalid-price (err u103))
(define-constant err-invalid-period (err u104))
(define-constant err-auto-renew-disabled (err u105))
(define-constant err-content-not-found (err u404))
(define-constant err-unauthorized (err u106))
(define-constant err-paused (err u107))

;; Data Variables
(define-data-var next-content-id uint u1)
(define-data-var contract-paused bool false)

;; Data Maps
(define-map licenses 
    { content-id: uint, licensee: principal }
    { 
        expires: uint,
        license-type: (string-ascii 10),
        auto-renew: bool
    }
)

(define-map content-registry
    { content-id: uint }
    { 
        owner: principal,
        price: uint,
        license-type: (string-ascii 10),
        subscription-periods: (list 3 uint),
        active: bool
    }
)

;; Administrative Functions
(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set contract-paused (not (var-get contract-paused))))
    )
)

;; Helper Functions
(define-private (is-contract-paused)
    (var-get contract-paused)
)

(define-private (is-content-owner (content-id uint) (caller principal))
    (match (map-get? content-registry { content-id: content-id })
        content (is-eq (get owner content) caller)
        false
    )
)

;; Enhanced Content Management
(define-public (register-content 
    (price uint) 
    (license-type (string-ascii 10))
    (subscription-periods (list 3 uint)))
    (begin
        (asserts! (not (is-contract-paused)) err-paused)
        (let ((content-id (var-get next-content-id)))
            (map-set content-registry
                { content-id: content-id }
                { 
                    owner: tx-sender,
                    price: price,
                    license-type: license-type,
                    subscription-periods: subscription-periods,
                    active: true
                }
            )
            (var-set next-content-id (+ content-id u1))
            (ok content-id)
        )
    )
)

(define-public (remove-content (content-id uint))
    (begin
        (asserts! (not (is-contract-paused)) err-paused)
        (asserts! (is-content-owner content-id tx-sender) err-unauthorized)
        (match (map-get? content-registry { content-id: content-id })
            content (begin
                (map-set content-registry
                    { content-id: content-id }
                    (merge content { active: false })
                )
                (ok true)
            )
            (err err-content-not-found)
        )
    )
)

;; Enhanced License Management
(define-public (purchase-license 
    (content-id uint)
    (period-index uint)
    (auto-renew bool))
    (begin
        (asserts! (not (is-contract-paused)) err-paused)
        (let (
            (content (unwrap! (map-get? content-registry { content-id: content-id }) err-content-not-found))
            (existing-license (map-get? licenses { content-id: content-id, licensee: tx-sender }))
            (period (unwrap! (element-at (get subscription-periods content) period-index) err-invalid-period))
        )
            (asserts! (get active content) err-content-not-found)
            (asserts! (is-none existing-license) err-already-licensed)
            (try! (stx-transfer? (get price content) tx-sender (get owner content)))
            (map-set licenses
                { content-id: content-id, licensee: tx-sender }
                { 
                    expires: (+ block-height (* period u525))
                    license-type: (get license-type content),
                    auto-renew: auto-renew
                }
            )
            (ok true)
        )
    )
)

;; Enhanced Read-Only Functions
(define-read-only (has-valid-license (content-id uint) (address principal))
    (match (map-get? licenses { content-id: content-id, licensee: address })
        license (ok (and 
            (< block-height (get expires license))
            (get active (default-to 
                { active: false } 
                (map-get? content-registry { content-id: content-id })
            ))
        ))
        (err err-not-licensed)
    )
)

[Previous functions remain unchanged...]

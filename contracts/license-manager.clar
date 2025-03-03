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
(define-constant err-rate-limited (err u108))
(define-constant err-reentrancy (err u109))

;; Data Variables
(define-data-var next-content-id uint u1)
(define-data-var contract-paused bool false)
(define-data-var last-operation uint u0)

;; Enhanced Data Maps
(define-map licenses 
    { content-id: uint, licensee: principal }
    { 
        expires: uint,
        license-type: (string-ascii 10),
        auto-renew: bool,
        last-renewed: uint
    }
)

(define-map content-registry
    { content-id: uint }
    { 
        owner: principal,
        price: uint,
        license-type: (string-ascii 10),
        subscription-periods: (list 3 uint),
        active: bool,
        metadata: (optional (string-utf8 256))
    }
)

(define-map rate-limits
    { user: principal }
    { last-purchase: uint, count: uint }
)

;; Reentrancy Protection
(define-data-var reentrancy-guard uint u0)

(define-private (check-reentrancy)
    (begin
        (asserts! (is-eq (var-get reentrancy-guard) u0) err-reentrancy)
        (var-set reentrancy-guard u1)
        (ok true)
    )
)

(define-private (release-reentrancy)
    (var-set reentrancy-guard u0)
)

;; Rate Limiting
(define-private (check-rate-limit (user principal))
    (let ((current-limit (default-to 
        { last-purchase: u0, count: u0 }
        (map-get? rate-limits { user: user }))))
        (if (is-eq (get last-purchase current-limit) block-height)
            (asserts! (< (get count current-limit) u5) err-rate-limited)
            (map-set rate-limits
                { user: user }
                { last-purchase: block-height, count: u1 }
            )
        )
    )
)

;; Enhanced Content Management
(define-public (register-content 
    (price uint) 
    (license-type (string-ascii 10))
    (subscription-periods (list 3 uint))
    (metadata (optional (string-utf8 256))))
    (begin
        (asserts! (not (is-contract-paused)) err-paused)
        (asserts! (> price u0) err-invalid-price)
        (let ((content-id (var-get next-content-id)))
            (map-set content-registry
                { content-id: content-id }
                { 
                    owner: tx-sender,
                    price: price,
                    license-type: license-type,
                    subscription-periods: subscription-periods,
                    active: true,
                    metadata: metadata
                }
            )
            (var-set next-content-id (+ content-id u1))
            (ok content-id)
        )
    )
)

;; Enhanced License Purchase
(define-public (purchase-license 
    (content-id uint)
    (period-index uint)
    (auto-renew bool))
    (begin
        (try! (check-reentrancy))
        (asserts! (not (is-contract-paused)) err-paused)
        (try! (check-rate-limit tx-sender))
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
                    expires: (+ block-height (* period u525)),
                    license-type: (get license-type content),
                    auto-renew: auto-renew,
                    last-renewed: block-height
                }
            )
            (release-reentrancy)
            (ok true)
        )
    )
)

;; Batch License Verification
(define-read-only (verify-multiple-licenses (content-ids (list 10 uint)) (address principal))
    (fold check-license content-ids (ok true))
)

(define-private (check-license (content-id uint) (previous-result (response bool uint)))
    (match previous-result
        success (has-valid-license content-id address)
        failure failure
    )
)

;; License Transfer
(define-public (transfer-license (content-id uint) (recipient principal))
    (begin
        (asserts! (not (is-contract-paused)) err-paused)
        (let ((license (unwrap! (map-get? licenses { content-id: content-id, licensee: tx-sender }) err-not-licensed)))
            (map-delete licenses { content-id: content-id, licensee: tx-sender })
            (map-set licenses
                { content-id: content-id, licensee: recipient }
                license
            )
            (ok true)
        )
    )
)

[Previous functions remain unchanged...]

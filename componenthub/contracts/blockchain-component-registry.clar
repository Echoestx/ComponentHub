;; Web3 Component Hub - Modular Development Marketplace
;; Decentralized registry for reusable blockchain components

;; Constants
(define-constant hub-admin tx-sender)
(define-constant err-admin-required (err u300))
(define-constant err-component-missing (err u301))
(define-constant err-permission-denied (err u302))
(define-constant err-insufficient-funds (err u303))
(define-constant err-duplicate-component (err u304))
(define-constant err-invalid-parameter (err u305))

;; Data Variables
(define-data-var transaction-fee-rate uint u200) ;; 2% transaction fee

;; Data Maps
(define-map blockchain-components
  { component-id: (string-ascii 32) }
  {
    builder: principal,
    component-name: (string-utf8 60),
    description: (string-utf8 400),
    category: (string-ascii 24), ;; "defi", "nft", "governance", "utility"
    usage-fee: uint,
    rental-fee: uint,
    deployment-count: uint,
    total-income: uint,
    status: bool,
    repo-hash: (string-ascii 46) ;; IPFS hash for component code
  }
)

(define-map component-access
  { developer: principal, component-id: (string-ascii 32) }
  {
    access-type: (string-ascii 10), ;; "rental" or "owned"
    expiry-height: uint,
    usage-credits: uint,
    investment: uint
  }
)

(define-map component-feedback
  { component-id: (string-ascii 32), reviewer: principal }
  {
    score: uint, ;; 1-5 quality score
    feedback: (string-utf8 350),
    review-height: uint
  }
)

(define-map builder-revenue principal uint)

;; Read-only functions
(define-read-only (get-component (component-id (string-ascii 32)))
  (map-get? blockchain-components { component-id: component-id })
)

(define-read-only (get-access-rights (developer principal) (component-id (string-ascii 32)))
  (map-get? component-access { developer: developer, component-id: component-id })
)

(define-read-only (get-feedback (component-id (string-ascii 32)) (reviewer principal))
  (map-get? component-feedback { component-id: component-id, reviewer: reviewer })
)

(define-read-only (get-builder-revenue (builder principal))
  (default-to u0 (map-get? builder-revenue builder))
)

(define-read-only (can-deploy-component (developer principal) (component-id (string-ascii 32)))
  (let (
    (access (get-access-rights developer component-id))
  )
    (match access
      access-data
        (or 
          (> (get usage-credits access-data) u0)
          (> (get expiry-height access-data) block-height)
        )
      false
    )
  )
)

;; Public functions

;; Register new component
(define-public (register-component
    (component-id (string-ascii 32))
    (component-name (string-utf8 60))
    (description (string-utf8 400))
    (category (string-ascii 24))
    (usage-fee uint)
    (rental-fee uint)
    (repo-hash (string-ascii 46))
  )
  (let (
    (existing-component (get-component component-id))
  )
    (asserts! (is-none existing-component) err-duplicate-component)
    (ok (map-set blockchain-components
      { component-id: component-id }
      {
        builder: tx-sender,
        component-name: component-name,
        description: description,
        category: category,
        usage-fee: usage-fee,
        rental-fee: rental-fee,
        deployment-count: u0,
        total-income: u0,
        status: true,
        repo-hash: repo-hash
      }
    ))
  )
)

;; Rent component temporarily
(define-public (rent-component (component-id (string-ascii 32)))
  (let (
    (component (unwrap! (get-component component-id) err-component-missing))
    (rental-price (get rental-fee component))
    (hub-fee (/ (* rental-price (var-get transaction-fee-rate)) u10000))
    (builder-payment (- rental-price hub-fee))
  )
    (asserts! (get status component) err-component-missing)
    (try! (stx-transfer? rental-price tx-sender (as-contract tx-sender)))
    
    ;; Update component statistics
    (map-set blockchain-components
      { component-id: component-id }
      (merge component {
        deployment-count: (+ (get deployment-count component) u1),
        total-income: (+ (get total-income component) rental-price)
      })
    )
    
    ;; Grant rental access
    (map-set component-access
      { developer: tx-sender, component-id: component-id }
      {
        access-type: "rental",
        expiry-height: (+ block-height u2160), ;; 15 days
        usage-credits: u0,
        investment: rental-price
      }
    )
    
    ;; Pay builder
    (map-set builder-revenue
      (get builder component)
      (+ (get-builder-revenue (get builder component)) builder-payment)
    )
    
    (ok true)
  )
)

;; Purchase usage credits
(define-public (buy-usage-credits (component-id (string-ascii 32)) (credit-amount uint))
  (let (
    (component (unwrap! (get-component component-id) err-component-missing))
    (total-price (* (get usage-fee component) credit-amount))
    (hub-fee (/ (* total-price (var-get transaction-fee-rate)) u10000))
    (builder-payment (- total-price hub-fee))
  )
    (asserts! (get status component) err-component-missing)
    (try! (stx-transfer? total-price tx-sender (as-contract tx-sender)))
    
    ;; Update component statistics
    (map-set blockchain-components
      { component-id: component-id }
      (merge component {
        deployment-count: (+ (get deployment-count component) u1),
        total-income: (+ (get total-income component) total-price)
      })
    )
    
    ;; Update or create access record
    (let (
      (existing-access (get-access-rights tx-sender component-id))
    )
      (match existing-access
        access-data
          (map-set component-access
            { developer: tx-sender, component-id: component-id }
            (merge access-data {
              usage-credits: (+ (get usage-credits access-data) credit-amount),
              investment: (+ (get investment access-data) total-price)
            })
          )
        (map-set component-access
          { developer: tx-sender, component-id: component-id }
          {
            access-type: "owned",
            expiry-height: u0,
            usage-credits: credit-amount,
            investment: total-price
          }
        )
      )
    )
    
    ;; Pay builder
    (map-set builder-revenue
      (get builder component)
      (+ (get-builder-revenue (get builder component)) builder-payment)
    )
    
    (ok true)
  )
)

;; Deploy component (consumes credits or checks rental)
(define-public (deploy-component (component-id (string-ascii 32)))
  (let (
    (component (unwrap! (get-component component-id) err-component-missing))
    (access (unwrap! (get-access-rights tx-sender component-id) err-permission-denied))
  )
    (asserts! (get status component) err-component-missing)
    
    ;; Check access rights and consume
    (if (is-eq (get access-type access) "owned")
      (begin
        (asserts! (> (get usage-credits access) u0) err-permission-denied)
        (map-set component-access
          { developer: tx-sender, component-id: component-id }
          (merge access {
            usage-credits: (- (get usage-credits access) u1)
          })
        )
      )
      (asserts! (> (get expiry-height access) block-height) err-permission-denied)
    )
    
    (ok true)
  )
)

;; Submit feedback for component
(define-public (submit-feedback
    (component-id (string-ascii 32))
    (score uint)
    (feedback (string-utf8 350))
  )
  (let (
    (component (unwrap! (get-component component-id) err-component-missing))
  )
    (asserts! (and (>= score u1) (<= score u5)) err-invalid-parameter)
    (asserts! (can-deploy-component tx-sender component-id) err-permission-denied)
    
    (ok (map-set component-feedback
      { component-id: component-id, reviewer: tx-sender }
      {
        score: score,
        feedback: feedback,
        review-height: block-height
      }
    ))
  )
)

;; Builder claims revenue
(define-public (claim-revenue)
  (let (
    (revenue (get-builder-revenue tx-sender))
  )
    (asserts! (> revenue u0) err-component-missing)
    (try! (as-contract (stx-transfer? revenue tx-sender tx-sender)))
    (map-set builder-revenue tx-sender u0)
    (ok revenue)
  )
)

;; Update component details
(define-public (update-component
    (component-id (string-ascii 32))
    (component-name (string-utf8 60))
    (description (string-utf8 400))
    (usage-fee uint)
    (rental-fee uint)
    (repo-hash (string-ascii 46))
    (status bool)
  )
  (let (
    (component (unwrap! (get-component component-id) err-component-missing))
  )
    (asserts! (is-eq (get builder component) tx-sender) err-permission-denied)
    
    (ok (map-set blockchain-components
      { component-id: component-id }
      (merge component {
        component-name: component-name,
        description: description,
        usage-fee: usage-fee,
        rental-fee: rental-fee,
        repo-hash: repo-hash,
        status: status
      })
    ))
  )
)

;; Admin function to adjust fees
(define-public (adjust-transaction-fee (new-fee-rate uint))
  (begin
    (asserts! (is-eq tx-sender hub-admin) err-admin-required)
    (asserts! (<= new-fee-rate u500) err-invalid-parameter) ;; Max 5%
    (ok (var-set transaction-fee-rate new-fee-rate))
  )
)
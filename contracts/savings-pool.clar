;; title: savings-pool
;; version: 1.0.0
;; summary: Simple savings pool for earning fixed interest on STX deposits
;; description: A DeFi savings contract that allows users to deposit STX and earn 5% annual interest

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_NO_DEPOSIT (err u103))
(define-constant ERR_POOL_DISABLED (err u104))
(define-constant ERR_MINIMUM_DEPOSIT (err u105))

;; Pool configuration
(define-constant ANNUAL_INTEREST_RATE u5) ;; 5% annual interest
(define-constant BLOCKS_PER_YEAR u52560) ;; Approximately 52,560 blocks per year (10 min blocks)
(define-constant MINIMUM_DEPOSIT u1000000) ;; 1 STX minimum deposit (in microSTX)
(define-constant PRECISION u10000) ;; For percentage calculations

;; data vars
(define-data-var pool-enabled bool true)
(define-data-var total-deposits uint u0)
(define-data-var total-interest-paid uint u0)
(define-data-var pool-creation-block uint u0)

;; data maps
;; User deposit information
(define-map user-deposits
  principal
  {
    amount: uint,
    deposit-block: uint,
    last-claim-block: uint,
    total-interest-earned: uint,
  }
)

;; User deposit history for tracking
(define-map user-history
  principal
  (list
    100
    {
      action: (string-ascii 10), ;; "deposit" or "withdraw"
      amount: uint,
      block-height: uint,
      interest-earned: uint,
    }
  )
)

;; Pool statistics tracking
(define-map daily-stats
  uint ;; block height (rounded to day)
  {
    total-deposits: uint,
    active-users: uint,
    interest-distributed: uint,
  }
)

;; public functions

;; Initialize the pool (called once by contract owner)
(define-public (initialize-pool)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (var-set pool-creation-block stacks-block-height)
    (ok true)
  )
)

;; Deposit STX to earn interest
(define-public (deposit (amount uint))
  (let (
      (current-deposit (default-to {
        amount: u0,
        deposit-block: u0,
        last-claim-block: u0,
        total-interest-earned: u0,
      }
        (map-get? user-deposits tx-sender)
      ))
      (current-amount (get amount current-deposit))
      (new-total-amount (+ current-amount amount))
    )
    (asserts! (var-get pool-enabled) ERR_POOL_DISABLED)
    (asserts! (>= amount MINIMUM_DEPOSIT) ERR_MINIMUM_DEPOSIT)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)

    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; If user has existing deposit, claim interest first
    (if (> current-amount u0)
      (begin
        (try! (claim-interest))
        true
      )
      true
    )

    ;; Update user deposit
    (map-set user-deposits tx-sender {
      amount: new-total-amount,
      deposit-block: stacks-block-height,
      last-claim-block: stacks-block-height,
      total-interest-earned: (get total-interest-earned current-deposit),
    })

    ;; Update total deposits
    (var-set total-deposits (+ (var-get total-deposits) amount))

    ;; Add to user history
    (let ((current-history (default-to (list) (map-get? user-history tx-sender))))
      (map-set user-history tx-sender
        (unwrap!
          (as-max-len?
            (append current-history {
              action: "deposit",
              amount: amount,
              block-height: stacks-block-height,
              interest-earned: u0,
            })
            u100
          )
          (err u106)
        ))
    )

    (ok true)
  )
)

;; Withdraw deposited STX plus earned interest
(define-public (withdraw (amount uint))
  (let (
      (user-deposit (unwrap! (map-get? user-deposits tx-sender) ERR_NO_DEPOSIT))
      (deposited-amount (get amount user-deposit))
      (earned-interest (calculate-interest tx-sender))
      (total-available (+ deposited-amount earned-interest))
    )
    (asserts! (var-get pool-enabled) ERR_POOL_DISABLED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (<= amount total-available) ERR_INSUFFICIENT_BALANCE)

    ;; Claim any pending interest first
    (try! (claim-interest))

    ;; Calculate new deposit amount
    (let ((new-deposit-amount (- deposited-amount amount)))
      ;; Update or remove user deposit
      (if (> new-deposit-amount u0)
        (map-set user-deposits tx-sender {
          amount: new-deposit-amount,
          deposit-block: stacks-block-height,
          last-claim-block: stacks-block-height,
          total-interest-earned: (get total-interest-earned user-deposit),
        })
        (map-delete user-deposits tx-sender)
      )

      ;; Update total deposits
      (var-set total-deposits (- (var-get total-deposits) amount))

      ;; Transfer STX to user
      (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))

      ;; Add to user history
      (let ((current-history (default-to (list) (map-get? user-history tx-sender))))
        (map-set user-history tx-sender
          (unwrap!
            (as-max-len?
              (append current-history {
                action: "withdraw",
                amount: amount,
                block-height: stacks-block-height,
                interest-earned: earned-interest,
              })
              u100
            )
            (err u106)
          ))
      )

      (ok true)
    )
  )
)

;; Claim earned interest without withdrawing principal
(define-public (claim-interest)
  (let (
      (user-deposit (unwrap! (map-get? user-deposits tx-sender) ERR_NO_DEPOSIT))
      (earned-interest (calculate-interest tx-sender))
    )
    (asserts! (var-get pool-enabled) ERR_POOL_DISABLED)
    (asserts! (> earned-interest u0) (err u107))

    ;; Update last claim block
    (map-set user-deposits tx-sender {
      amount: (get amount user-deposit),
      deposit-block: (get deposit-block user-deposit),
      last-claim-block: stacks-block-height,
      total-interest-earned: (+ (get total-interest-earned user-deposit) earned-interest),
    })

    ;; Update total interest paid
    (var-set total-interest-paid
      (+ (var-get total-interest-paid) earned-interest)
    )

    ;; Transfer interest to user
    (try! (as-contract (stx-transfer? earned-interest tx-sender tx-sender)))

    ;; Add to user history
    (let ((current-history (default-to (list) (map-get? user-history tx-sender))))
      (map-set user-history tx-sender
        (unwrap!
          (as-max-len?
            (append current-history {
              action: "claim",
              amount: u0,
              block-height: stacks-block-height,
              interest-earned: earned-interest,
            })
            u100
          )
          (err u106)
        ))
    )

    (ok earned-interest)
  )
)

;; Admin function to toggle pool enabled/disabled
(define-public (set-pool-enabled (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (var-set pool-enabled enabled)
    (ok true)
  )
)

;; Emergency withdraw for admin (in case of issues)
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT_OWNER)))
    (ok true)
  )
)

;; read only functions

;; Calculate interest earned for a user
(define-read-only (calculate-interest (user principal))
  (match (map-get? user-deposits user)
    user-deposit (let (
        (deposit-amount (get amount user-deposit))
        (last-claim-block (get last-claim-block user-deposit))
        (blocks-elapsed (- stacks-block-height last-claim-block))
        (annual-interest (/ (* deposit-amount ANNUAL_INTEREST_RATE) u100))
        (interest-per-block (/ annual-interest BLOCKS_PER_YEAR))
        (total-interest (* interest-per-block blocks-elapsed))
      )
      total-interest
    )
    u0
  )
)

;; Get user's deposit information
(define-read-only (get-user-deposit (user principal))
  (map-get? user-deposits user)
)

;; Get user's current balance (deposit + earned interest)
(define-read-only (get-user-balance (user principal))
  (match (map-get? user-deposits user)
    user-deposit (let (
        (deposit-amount (get amount user-deposit))
        (earned-interest (calculate-interest user))
      )
      {
        deposited: deposit-amount,
        earned-interest: earned-interest,
        total-balance: (+ deposit-amount earned-interest),
        total-earned: (+ (get total-interest-earned user-deposit) earned-interest),
      }
    )
    {
      deposited: u0,
      earned-interest: u0,
      total-balance: u0,
      total-earned: u0,
    }
  )
)

;; Get user's transaction history
(define-read-only (get-user-history (user principal))
  (default-to (list) (map-get? user-history user))
)

;; Get pool statistics
(define-read-only (get-pool-stats)
  {
    total-deposits: (var-get total-deposits),
    total-interest-paid: (var-get total-interest-paid),
    pool-enabled: (var-get pool-enabled),
    pool-creation-block: (var-get pool-creation-block),
    current-block: stacks-block-height,
    annual-interest-rate: ANNUAL_INTEREST_RATE,
    minimum-deposit: MINIMUM_DEPOSIT,
  }
)

;; Calculate potential interest for a given amount and time
(define-read-only (calculate-potential-interest
    (amount uint)
    (blocks uint)
  )
  (let (
      (annual-interest (/ (* amount ANNUAL_INTEREST_RATE) u100))
      (interest-per-block (/ annual-interest BLOCKS_PER_YEAR))
      (total-interest (* interest-per-block blocks))
    )
    total-interest
  )
)

;; Get contract information
(define-read-only (get-contract-info)
  {
    name: "Simple Savings Pool",
    version: "1.0.0",
    contract-owner: CONTRACT_OWNER,
    annual-rate: ANNUAL_INTEREST_RATE,
    minimum-deposit: MINIMUM_DEPOSIT,
  }
)

;; Check if pool is enabled
(define-read-only (is-pool-enabled)
  (var-get pool-enabled)
)

;; Get total value locked in the pool
(define-read-only (get-total-value-locked)
  (+ (var-get total-deposits) (var-get total-interest-paid))
)

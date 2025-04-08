;; Title: AnalytixStake Protocol
;; Summary: Advanced Staking & Governance System with Tiered Rewards and Bitcoin-Aligned Security
;; Description:
;; A next-generation DeFi protocol enabling STX holders to participate in secure staking mechanisms
;; with dynamic reward structures while governing protocol evolution through decentralized voting.
;; Features multi-tier staking with compounding rewards, time-locked positions for bonus yields,
;; and Bitcoin-compliant security architecture. Integrated governance allows stakeholders to propose
;; and vote on protocol upgrades directly on-chain. Built on Stacks Layer 2 for maximum Bitcoin
;; finality, featuring emergency safeguards, cooldown withdrawal mechanics, and sophisticated
;; risk management parameters.

;; Key Innovations:
;; - Tiered reward multipliers based on stake size and lock-up commitment
;; - Governance-as-a-Stake mechanism with voting power proportional to position
;; - Bitcoin-native security model with STX/BTC dual-chain compliance
;; - Adaptive cooldown system preventing sudden liquidity shocks
;; - Multi-parameter emergency stops for protocol protection

;; token definitions
(define-fungible-token ANALYTICS-TOKEN u0)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-PROTOCOL (err u1001))
(define-constant ERR-INVALID-AMOUNT (err u1002))
(define-constant ERR-INSUFFICIENT-STX (err u1003))
(define-constant ERR-COOLDOWN-ACTIVE (err u1004))
(define-constant ERR-NO-STAKE (err u1005))
(define-constant ERR-BELOW-MINIMUM (err u1006))
(define-constant ERR-PAUSED (err u1007))

;; data vars
(define-data-var contract-paused bool false)
(define-data-var emergency-mode bool false)
(define-data-var stx-pool uint u0)
(define-data-var base-reward-rate uint u500) ;; 5% base rate (100 = 1%)
(define-data-var bonus-rate uint u100) ;; 1% bonus for longer staking
(define-data-var minimum-stake uint u1000000) ;; Minimum stake amount
(define-data-var cooldown-period uint u1440) ;; 24 hour cooldown in blocks
(define-data-var proposal-count uint u0)

;; data maps
(define-map Proposals
    { proposal-id: uint }
    {
        creator: principal,
        description: (string-utf8 256),
        start-block: uint,
        end-block: uint,
        executed: bool,
        votes-for: uint,
        votes-against: uint,
        minimum-votes: uint
    }
)

(define-map UserPositions
    principal
    {
        total-collateral: uint,
        total-debt: uint,
        health-factor: uint,
        last-updated: uint,
        stx-staked: uint,
        analytics-tokens: uint,
        voting-power: uint,
        tier-level: uint,
        rewards-multiplier: uint
    }
)

(define-map StakingPositions
    principal
    {
        amount: uint,
        start-block: uint,
        last-claim: uint,
        lock-period: uint,
        cooldown-start: (optional uint),
        accumulated-rewards: uint
    }
)

(define-map TierLevels
    uint
    {
        minimum-stake: uint,
        reward-multiplier: uint,
        features-enabled: (list 10 bool)
    }
)

;; private functions
(define-private (get-tier-info (stake-amount uint))
    (if (>= stake-amount u10000000)
        {tier-level: u3, reward-multiplier: u200}
        (if (>= stake-amount u5000000)
            {tier-level: u2, reward-multiplier: u150}
            {tier-level: u1, reward-multiplier: u100}
        )
    )
)

(define-private (calculate-lock-multiplier (lock-period uint))
    (if (>= lock-period u8640)     ;; 2 months
        u150                       ;; 1.5x multiplier
        (if (>= lock-period u4320) ;; 1 month
            u125                   ;; 1.25x multiplier
            u100                   ;; 1x multiplier (no lock)
        )
    )
)

(define-private (calculate-rewards (user principal) (blocks uint))
    (let
        (
            (staking-position (unwrap! (map-get? StakingPositions user) u0))
            (user-position (unwrap! (map-get? UserPositions user) u0))
            (stake-amount (get amount staking-position))
            (base-rate (var-get base-reward-rate))
            (multiplier (get rewards-multiplier user-position))
        )
        (/ (* (* (* stake-amount base-rate) multiplier) blocks) u14400000)
    )
)

(define-private (is-valid-description (desc (string-utf8 256)))
    (and 
        (>= (len desc) u10)   ;; Minimum description length
        (<= (len desc) u256)  ;; Maximum description length
    )
)

(define-private (is-valid-lock-period (lock-period uint))
    (or 
        (is-eq lock-period u0)    ;; No lock
        (is-eq lock-period u4320) ;; 1 month
        (is-eq lock-period u8640) ;; 2 months
    )
)

(define-private (is-valid-voting-period (period uint))
    (and 
        (>= period u100)      ;; Minimum voting blocks
        (<= period u2880)     ;; Maximum voting blocks (approximately 1 day)
    )
)
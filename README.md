# AnalytixStake Protocol - Smart Contract Documentation

## Table of Contents

1. [Protocol Overview](#protocol-overview)
2. [Architectural Features](#architectural-features)
3. [Core Smart Contract Components](#core-smart-contract-components)
4. [Staking Mechanics](#staking-mechanics)
5. [Governance System](#governance-system)
6. [Security Architecture](#security-architecture)
7. [Tiered Reward System](#tiered-reward-system)
8. [Error Reference](#error-reference)
9. [Contract Administration](#contract-administration)

<a name="protocol-overview"></a>

## 1. Protocol Overview

AnalytixStake is a next-generation DeFi protocol combining advanced staking mechanisms with decentralized governance, built on Stacks (Bitcoin Layer 2). The system enables STX holders to:

- Earn compounding rewards through tiered staking positions
- Participate in protocol governance with stake-weighted voting
- Benefit from Bitcoin-finalized security guarantees
- Access premium features through multi-level participation tiers

<a name="architectural-features"></a>

## 2. Architectural Features

### 2.1 Core Innovations

- **Bitcoin-Native Security**: Leverages Stacks Layer 2 for Bitcoin settlement finality
- **Adaptive Reward Engine**: Dynamic yield calculation with multiple multiplier factors
- **Governance-as-a-Stake (GaaS)**: Protocol control proportional to stake commitment
- **Liquidity Protection**: Cooldown mechanics and emergency circuit breakers

### 2.2 Technical Specifications

- **Base Reward Rate**: 5% APY (adjustable through governance)
- **Lock Period Options**: 0 (flexible), 4320 blocks (~1 month), 8640 blocks (~2 months)
- **Minimum Stake**: 1,000,000 uSTX (1 STX)
- **Cooldown Period**: 1440 blocks (~24 hours)

<a name="core-smart-contract-components"></a>

## 3. Core Smart Contract Components

### 3.1 Data Storage

```clarity
;; Primary Data Structures
UserPositions: Principal -> {
  stx-staked: uint,
  analytics-tokens: uint,
  voting-power: uint,
  tier-level: uint,
  rewards-multiplier: uint
}

StakingPositions: Principal -> {
  amount: uint,
  start-block: uint,
  lock-period: uint,
  cooldown-start: (optional uint),
  accumulated-rewards: uint
}

TierLevels: uint -> {
  minimum-stake: uint,
  reward-multiplier: uint,
  features-enabled: [bool; 10]
}
```

### 3.2 System Constants

| Constant           | Value       | Description                       |
| ------------------ | ----------- | --------------------------------- |
| `CONTRACT-OWNER`   | tx-sender   | Deployment administrator          |
| `minimum-stake`    | 1,000,000   | Minimum STX to participate (uSTX) |
| `cooldown-period`  | 1440 blocks | Withdrawal waiting period         |
| `base-reward-rate` | 500         | 5% base APR (100 = 1%)            |

<a name="staking-mechanics"></a>

## 4. Staking Mechanics

### 4.1 Staking Operations

**Stake STX (`stake-stx`)**

```clarity
(stake-stx uint uint) -> (response bool)
```

- Parameters:
  - `amount`: STX amount in uSTX (≥1,000,000)
  - `lock-period`: 0, 4320, or 8640 blocks
- Effects:
  - Transfers STX to contract custody
  - Updates tier level and reward multiplier
  - Starts reward accumulation timer

**Initiate Unstake (`initiate-unstake`)**

```clarity
(initiate-unstake uint) -> (response bool)
```

- Triggers cooldown period
- Requires full clearance of existing rewards

**Complete Unstake (`complete-unstake`)**

```clarity
(complete-unstake) -> (response bool)
```

- Available after cooldown expiration
- Returns principal + rewards in single transaction

### 4.2 Reward Calculation

Rewards accumulate per block using:

```
Rewards = (StakedAmount * BaseRate * Multiplier * ElapsedBlocks) / 14,400,000
```

Where:

- `Multiplier = TierMultiplier * LockMultiplier`
- Base rate = 5% (adjustable via governance)

<a name="governance-system"></a>

## 5. Governance System

### 5.1 Proposal Lifecycle

1. **Creation**:

   - Minimum 1,000,000 voting power required
   - 10-256 character description
   - Voting period: 100-2880 blocks

2. **Voting**:

   - Weight proportional to staked amount
   - Votes immutable once cast

3. **Execution**:
   - Requires >50% approval
   - Minimum 1,000,000 total votes
   - Executable after voting period

### 5.2 Governance Functions

**Create Proposal (`create-proposal`)**

```clarity
(create-proposal (string-utf8 256) uint) -> (response uint)
```

**Cast Vote (`vote-on-proposal`)**

```clarity
(vote-on-proposal uint bool) -> (response bool)
```

<a name="security-architecture"></a>

## 6. Security Architecture

### 6.1 Protection Mechanisms

- **Emergency Mode**: Freezes all operations when activated
- **Cooldown System**: 24h withdrawal delay prevents bank runs
- **Protocol Pause**: Contract owner can suspend operations
- **Parameter Validation**: Strict type/range checking for all inputs

### 6.2 Bitcoin Integration

- Settlement finality through Stacks L2
- STX/BTC atomic swap compatibility
- Bitcoin block height synchronization

<a name="tiered-reward-system"></a>

## 7. Tiered Reward System

### 7.1 Tier Levels

| Tier | Minimum STX | Multiplier | Features                          |
| ---- | ----------- | ---------- | --------------------------------- |
| 1    | 1 STX       | 1x         | Basic staking, governance voting  |
| 2    | 5 STX       | 1.5x       | +Priority voting, early features  |
| 3    | 10 STX      | 2x         | +Premium analytics, fee discounts |

### 7.2 Lock-Up Bonuses

| Lock Period | Multiplier | Minimum Tier |
| ----------- | ---------- | ------------ |
| 0 blocks    | 1x         | 1            |
| 1 month     | 1.25x      | 2            |
| 2 months    | 1.5x       | 3            |

<a name="error-reference"></a>

## 8. Error Reference

| Code | Constant             | Description                     |
| ---- | -------------------- | ------------------------------- |
| 1000 | ERR-NOT-AUTHORIZED   | Unauthorized operation attempt  |
| 1001 | ERR-INVALID-PROTOCOL | Invalid parameter/state         |
| 1002 | ERR-INVALID-AMOUNT   | Incorrect numeric value         |
| 1003 | ERR-INSUFFICIENT-STX | Insufficient STX balance        |
| 1004 | ERR-COOLDOWN-ACTIVE  | Withdrawal cooldown in progress |
| 1005 | ERR-NO-STAKE         | No active staking position      |
| 1006 | ERR-BELOW-MINIMUM    | Below minimum requirement       |
| 1007 | ERR-PAUSED           | Contract operations suspended   |

<a name="contract-administration"></a>

## 9. Contract Administration

### 9.1 Emergency Controls

```clarity
(pause-contract)  -> (response bool)  ;; Freeze all operations
(resume-contract) -> (response bool)  ;; Resume normal operations
```

### 9.2 Parameter Adjustment

Governance-controlled parameters:

- Base reward rate
- Minimum stake amount
- Cooldown duration
- Tier thresholds

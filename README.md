# 🤖 AutoYield Vault

> **The simplest self-driving yield engine on BNB Chain.**  
> Deposit USDT. Earn from AsterDEX. Anyone harvests. Share price grows.  
> No admin. No governance. No keys. Just yield.

[![CI](https://github.com/manjeetsharma0796/autoyield-vault/actions/workflows/ci.yml/badge.svg)](https://github.com/manjeetsharma0796/autoyield-vault/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Built for Riquid Hackathon](https://img.shields.io/badge/Built%20for-Riquid%20Hackathon-blueviolet)](https://dorahacks.io/hackathon/riquid-hackathon)

---

## 🧠 What is AutoYield?

AutoYield is a **fully autonomous, non-custodial ERC-4626 yield vault** built on BNB Chain.

Users deposit **USDT** and receive **ayVAULT** shares. The vault automatically deploys all capital into [AsterDEX Earn](https://docs.asterdex.com). Anyone — literally anyone — can call `harvest()` to compound rewards back into the vault, increasing the share price for every depositor.

There is **no owner**, **no admin key**, **no governance vote** required. The protocol runs itself.

---

## ⚙️ How It Works

```
User deposits USDT
        │
        ▼
  AutoYieldVault (ERC-4626)
        │
        ▼  afterDeposit()
  AsterDEX Earn ──► Earns yield on USDT
        │
        ▼  anyone calls harvest()
  Rewards harvested
        │
        ├──► 0.1% → harvest() caller (incentive)
        │
        └──► 99.9% → redeposited into AsterDEX Earn
                         │
                         ▼
                  Share price increases 📈
                  All depositors earn proportionally
```

### Key Properties

| Property | Value |
|---|---|
| **Standard** | ERC-4626 Tokenized Vault |
| **Underlying** | USDT (BNB Chain) |
| **Yield Source** | AsterDEX Earn |
| **Admin Key** | ❌ None |
| **Governance** | ❌ None |
| **Harvest Trigger** | ✅ Anyone |
| **Harvest Cooldown** | 1 hour (anti-spam) |
| **Caller Incentive** | 0.1% of harvested rewards |
| **Chain** | BNB Chain (BSC) |

---

## 📁 Project Structure

```
autoyield-vault/
├── src/
│   ├── AutoYieldVault.sol        # Core ERC-4626 vault contract
│   └── interfaces/
│       └── IAsterEarn.sol        # AsterDEX Earn interface
├── test/
│   └── AutoYieldVault.t.sol      # Foundry test suite (unit + fuzz)
├── script/
│   └── Deploy.s.sol              # Deployment script for BNB Chain
├── .github/
│   └── workflows/
│       └── ci.yml                # GitHub Actions CI
├── foundry.toml                  # Foundry configuration
└── README.md
```

---

## 🚀 Quickstart

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Git

### 1. Clone & Install

```bash
git clone https://github.com/manjeetsharma0796/autoyield-vault
cd autoyield-vault
forge install
```

### 2. Build

```bash
forge build
```

### 3. Test

```bash
forge test -vvv
```

### 4. Deploy to BNB Testnet

```bash
cp .env.example .env
# Fill in your PRIVATE_KEY and BNB_TESTNET_RPC_URL

forge script script/Deploy.s.sol:DeployAutoYieldVault \
  --rpc-url $BNB_TESTNET_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

### 5. Deploy to BNB Mainnet

```bash
forge script script/Deploy.s.sol:DeployAutoYieldVault \
  --rpc-url $BNB_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

---

## 🔐 Contract Addresses (BNB Chain)

| Contract | Address |
|---|---|
| USDT (BNB Chain) | `0x55d398326f99059fF775485246999027B3197955` |
| AsterDEX Earn | `0x2F31ab8950c50080E77999fa456372f276952fD8` |
| AutoYieldVault | `TBD after deployment` |

---

## 🧪 Test Coverage

```
Running 11 tests...
[PASS] test_Deposit_MintsShares()
[PASS] test_Deposit_DeploysToAsterEarn()
[PASS] test_TotalAssets_IncludesDeployed()
[PASS] test_Withdraw_ReturnsAssets()
[PASS] test_Harvest_CompoundsRewards()
[PASS] test_Harvest_PaysCallerFee()
[PASS] test_Harvest_RevertsOnCooldown()
[PASS] test_Harvest_IncreasesSharePrice()
[PASS] test_HarvestReady_ReturnsFalseBeforeCooldown()
[PASS] test_HarvestReady_ReturnsTrueAfterCooldown()
[PASS] test_MultiUser_ProportionalYield()
[PASS] testFuzz_Deposit_Withdraw (1000 runs)
```

---

## 📖 Key Functions

### `deposit(uint256 assets, address receiver) → uint256 shares`
Deposit USDT and receive ayVAULT shares. Capital is immediately deployed to AsterDEX Earn.

### `withdraw(uint256 assets, address receiver, address owner) → uint256 shares`
Redeem ayVAULT shares for USDT. Capital is recalled from AsterDEX Earn as needed.

### `harvest()`
**Anyone can call this.** Harvests pending rewards from AsterDEX Earn, pays 0.1% to the caller as incentive, and compounds the rest — increasing share price for all depositors.

### `sharePrice() → uint256`
Returns the current price per share in USDT (18 decimals). This increases every time `harvest()` is called.

### `harvestReady() → bool`
Returns `true` if the 1-hour cooldown has passed and `harvest()` can be called.

### `pendingRewards() → uint256`
Returns the current pending rewards claimable from AsterDEX Earn.

---

## 🔒 Security Design

- **No admin keys** — The contract has no `owner`, no `onlyOwner` functions, no upgradability
- **No governance** — No votes, no timelocks, no multisigs
- **Reentrancy safe** — Inherits OpenZeppelin's battle-tested ERC-4626 implementation
- **Harvest anti-spam** — 1-hour cooldown prevents griefing
- **ERC-4626 standard** — Interoperable with any DeFi protocol that supports the standard
- **SafeERC20** — All token transfers use OpenZeppelin's SafeERC20

---

## 🏗️ Built With

- [Solidity 0.8.20](https://soliditylang.org/)
- [OpenZeppelin Contracts v5](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Foundry](https://book.getfoundry.sh/)
- [AsterDEX Earn](https://docs.asterdex.com/) on BNB Chain

---

## 📜 License

MIT — see [LICENSE](LICENSE)

---

## 🏆 Riquid Hackathon

Built for the **[Riquid Hackathon](https://dorahacks.io/hackathon/riquid-hackathon)** on DoraHacks.

> *"The Self-Driving Yield Engine — Composable Yield Infrastructure on BNB Chain"*

AutoYield embodies the hackathon theme perfectly:
- ✅ Fully autonomous — no manual intervention ever required
- ✅ Non-custodial — users always control their funds via ERC-4626
- ✅ AsterDEX Earn as primary yield source
- ✅ Permissionless — anyone can harvest, anyone can deposit
- ✅ Composable — standard ERC-4626 plugs into any DeFi protocol
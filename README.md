# OwnaFarm Smart Contracts

> Mantle Sepolia Testnet | Chain ID: 5003

## Contract Addresses

| Contract | Address |
|----------|---------|
| GoldToken | `0x...` |
| GoldFaucet | `0x...` |
| OwnaFarmNFT | `0x...` |
| OwnaFarmVault | `0x...` |

---

## Functions Reference

### GoldToken (ERC20)

| Function | Description |
|----------|-------------|
| `balanceOf(address)` | Get GOLD balance |
| `approve(spender, amount)` | Approve spender to use tokens |
| `transfer(to, amount)` | Transfer GOLD to address |

### GoldFaucet

| Function | Description |
|----------|-------------|
| `claim()` | Claim 10,000 GOLD (1x per 24h) |
| `canClaim(address)` | Check if address can claim |
| `timeUntilNextClaim(address)` | Seconds until next claim available |
| `getBalance()` | Faucet remaining balance |

### OwnaFarmNFT

| Function | Description |
|----------|-------------|
| `createInvoice(offtaker, targetFund, yieldBps, duration)` | Admin: Create new invoice |
| `invest(tokenId, amount)` | Invest GOLD into invoice |
| `harvest(investmentIdx)` | Claim principal + yield after maturity |
| `getInvestments(address)` | Get all investments by address |
| `getInvestmentCount(address)` | Count investments |
| `getAvailableInvoices()` | List all open invoices |
| `invoices(tokenId)` | Get invoice details |
| `deactivateInvoice(tokenId)` | Admin: Deactivate invoice |

### OwnaFarmVault

| Function | Description |
|----------|-------------|
| `depositYield(amount)` | Admin: Deposit yield reserve |
| `getYieldReserve()` | Check yield reserve balance |

---

## Setup & Deploy

```bash
# Install
forge install

# Build
forge build

# Test
forge test -vv

# Deploy
cp .env.example .env
# Edit .env with your PRIVATE_KEY

source .env
forge script script/Deploy.s.sol:DeployOwnaFarm --rpc-url $RPC_URL --broadcast
```

---

**Built by YeheskielTame (OwnaFarm Team Lead)**

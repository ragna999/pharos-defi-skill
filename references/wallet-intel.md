# Wallet Intelligence

## Overview
Analyze any wallet on Pharos: portfolio composition, transaction patterns, risk indicators, and activity summary.

## Capability: Wallet Analysis

### Method 1: On-Chain Query (via cast)

#### Step 1: Basic Balance
```bash
# Native token balance
cast balance $WALLET_ADDRESS --rpc-url $RPC
cast balance $WALLET_ADDRESS --rpc-url $RPC --ether
```

#### Step 2: ERC-20 Token Balances
```bash
# For each known token, check balance
cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $WALLET_ADDRESS --rpc-url $RPC
```

#### Step 3: Transaction History
```bash
# Get transaction count (nonce = number of txs sent)
cast nonce $WALLET_ADDRESS --rpc-url $RPC

# Get code at address (EOA vs contract)
cast code $WALLET_ADDRESS --rpc-url $RPC
```

#### Step 4: Risk Indicators
```bash
# Check if wallet is a contract (bots are often contracts)
CODE=$(cast code $WALLET_ADDRESS --rpc-url $RPC)
if [ "$CODE" != "0x" ]; then
  echo "WARNING: This is a contract address, not an EOA"
fi

# Check first transaction age
cast tx $FIRST_TX_HASH --rpc-url $RPC | grep blockNumber
```

### Risk Scoring

| Factor | Weight | Criteria |
|--------|--------|----------|
| Wallet age | 20 | >6mo = 100, 1-6mo = 70, <1mo = 30 |
| Transaction count | 15 | >100 = 100, 10-100 = 70, <10 = 30 |
| Is contract | 10 | EOA = 100, Contract = 30 |
| Known scam interaction | 25 | None = 100, Some = 0 |
| Diverse protocol usage | 15 | >5 = 100, 2-5 = 70, 1 = 30 |
| Consistent activity | 15 | Regular = 100, Sporadic = 50 |

### Output Template

```
=== WALLET INTELLIGENCE REPORT ===
Address: {address}
Chain: Pharos

PORTFOLIO:
  Native: {amount} PHRS/PROS
  Tokens: {count} tokens
  Total Value: ~${value}

ACTIVITY:
  Tx Count: {count}
  Wallet Age: {age}
  First Seen: {date}
  Type: {EOA/Contract}

RISK SCORE: {score}/100
VERDICT: {LOW_RISK/MEDIUM_RISK/HIGH_RISK}

# Token Safety Check

## Overview
Analyze any ERC-20 token on Pharos for safety risks: honeypot detection, rug pull indicators, holder concentration, contract verification, and tax analysis.

## Capability: Token Safety Analysis

### Method 1: On-Chain Contract Analysis (via cast)

#### Step 1: Get Basic Token Info
```bash
# Get token name
cast call $TOKEN_ADDRESS "name()(string)" --rpc-url $RPC

# Get token symbol
cast call $TOKEN_ADDRESS "symbol()(string)" --rpc-url $RPC

# Get total supply
cast call $TOKEN_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC

# Get decimals
cast call $TOKEN_ADDRESS "decimals()(uint8)" --rpc-url $RPC
```

#### Step 2: Check Owner & Admin Functions
```bash
# Check if token has owner
cast call $TOKEN_ADDRESS "owner()(address)" --rpc-url $RPC 2>/dev/null || echo "No owner function"

# Check if mintable
cast call $TOKEN_ADDRESS "mint(address,uint256)" --rpc-url $RPC 2>/dev/null && echo "MINTABLE - HIGH RISK" || echo "Not mintable"

# Check if pausable
cast call $TOKEN_ADDRESS "paused()(bool)" --rpc-url $RPC 2>/dev/null || echo "Not pausable"

# Check max transaction amount (anti-whale)
cast call $TOKEN_ADDRESS "maxTxAmount()(uint256)" --rpc-url $RPC 2>/dev/null || echo "No max tx limit"
```

#### Step 3: Holder Analysis
```bash
# Get balance of top holders (check first 10 addresses from explorer)
cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $HOLDER_ADDRESS --rpc-url $RPC
```

#### Step 4: Honeypot Detection
```bash
# Try to estimate gas for a sell (if this fails, might be honeypot)
cast call $TOKEN_ADDRESS "transfer(address,uint256)(bool)" $DEAD_ADDRESS 1000 --rpc-url $RPC 2>/dev/null && echo "Transfer OK" || echo "TRANSFER FAILED - Possible honeypot"

# Check if there's a hidden fee on transfer
# Compare expected vs actual output
```

### Method 2: External API Check

```bash
# GoPlus Security API (supports multiple chains)
curl -s "https://api.gopluslabs.io/api/v1/token_security/$CHAIN_ID?contract_addresses=$TOKEN_ADDRESS" | python3 -c "
import json,sys
data = json.load(sys.stdin)
token = data.get('result',{}).get('$TOKEN_ADDRESS.lower()',{})
print(f"Is Honeypot: {token.get('is_honeypot','unknown')}")
print(f"Owner Can Change Balance: {token.get('owner_change_balance','unknown')}")
print(f"Hidden Owner: {token.get('hidden_owner','unknown')}")
print(f"Self Destruct: {token.get('selfdestruct','unknown')}")
print(f"External Call: {token.get('external_call','unknown')}")
print(f"Buy Tax: {token.get('buy_tax','unknown')}")
print(f"Sell Tax: {token.get('sell_tax','unknown')}")
print(f"Holder Count: {token.get('holder_count','unknown')}")
print(f"Top 10 Holder Ratio: {token.get('top_10_holder_rate','unknown')}")
"
```

### Risk Scoring Formula

| Factor | Weight | Score |
|--------|--------|-------|
| Honeypot detected | 30 | 0 if yes, 100 if no |
| Owner can mint | 15 | 0 if yes, 100 if no |
| Hidden owner | 15 | 0 if yes, 100 if no |
| Buy/sell tax > 10% | 15 | 0 if >10%, 50 if 5-10%, 100 if <5% |
| Top 10 holder ratio > 50% | 10 | 0 if >80%, 50 if 50-80%, 100 if <50% |
| Contract verified | 10 | 0 if no, 100 if yes |
| External call risk | 5 | 0 if yes, 100 if no |

**Overall Score = weighted average**
- 80-100: LOW RISK (green)
- 50-79: MEDIUM RISK (yellow)
- 0-49: HIGH RISK (red)

### Output Template

```
=== TOKEN SAFETY REPORT ===
Token: {name} ({symbol})
Address: {address}
Chain: {chain}

RISK SCORE: {score}/100 ({verdict})

FINDINGS:
  [+] Contract verified: {yes/no}
  [+] Honeypot: {yes/no}
  [+] Mintable: {yes/no}
  [+] Owner can change balance: {yes/no}
  [+] Hidden owner: {yes/no}
  [+] Buy tax: {buy_tax}%
  [+] Sell tax: {sell_tax}%
  [+] Top 10 holder ratio: {ratio}%
  [+] External call risk: {yes/no}

VERDICT: {SAFE/CAUTION/AVOID}
REASON: {brief explanation}

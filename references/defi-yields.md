# DeFi Yield Scanner

## Overview
Scan and compare yield opportunities across DeFi protocols deployed on Pharos chain. Returns best APY, TVL, risk level, and protocol info.

## Capability: Yield Discovery

### Method 1: On-Chain Protocol Query (via cast)

#### Step 1: Discover Protocols
```bash
# Check known protocol contracts on Pharos
# Lending protocols (Aave-style)
cast call $LENDING_POOL "getReserveData(address)(tuple)" $TOKEN --rpc-url $RPC

# DEX pools (Uniswap-style) 
cast call $FACTORY "getPool(address,address,address)(address)" $TOKEN_A $TOKEN_B $FEE --rpc-url $RPC

# Staking contracts
cast call $STAKING "getRewardRate()(uint256)" --rpc-url $RPC
```

#### Step 2: Calculate APY
```bash
# For lending: APY = (supplyRatePerBlock * blocks_per_year) / 1e18
# For LP: APY = (fee_tier * volume_24h * 365) / (2 * liquidity)
# For staking: APY = (reward_rate * 365 * reward_price) / (staked_amount * token_price)
```

### Method 2: DeFiLlama API

```bash
# Get yields on Pharos chain
curl -s "https://yields.llama.fi/pools" | python3 -c "
import json,sys
data = json.load(sys.stdin)
pools = [p for p in data.get('data',[]) if 'pharos' in p.get('chain','').lower()]
pools.sort(key=lambda x: x.get('apy',0), reverse=True)
for p in pools[:10]:
    print(f"{p['project']}: {p['symbol']} — APY: {p['apy']:.2f}% | TVL: \${p.get('tvlUsd',0):,.0f}")
"
```

### Method 3: Manual Protocol Scan

For each known protocol on Pharos:
1. Get pool/token address from protocol docs
2. Query contract for yield parameters
3. Calculate APY from on-chain data
4. Compare across protocols

### Risk Categories

| Risk Level | Criteria |
|------------|----------|
| LOW | Blue-chip protocols, audited, high TVL (>$10M), stable assets |
| MEDIUM | Mid-tier protocols, some audit, medium TVL ($1-10M) |
| HIGH | New protocols, no audit, low TVL (<$1M), volatile assets |

### Output Template

```
=== PHAROS DEFI YIELDS ===
Scan Time: {timestamp}
Total Protocols: {count}

TOP YIELDS:
  1. {protocol} — {pair} — APY: {apy}% — TVL: ${tvl} — Risk: {risk}
  2. {protocol} — {pair} — APY: {apy}% — TVL: ${tvl} — Risk: {risk}
  3. {protocol} — {pair} — APY: {apy}% — TVL: ${tvl} — Risk: {risk}

BEST BY CATEGORY:
  Lending: {protocol} — {apy}%
  LP: {protocol} — {apy}%
  Staking: {protocol} — {apy}%

RISK WARNING: {appropriate warning}

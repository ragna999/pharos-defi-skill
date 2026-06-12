# Protocol Analytics

## Overview
Track protocol-level statistics on Pharos: TVL, volume, top gainers/losers, and ecosystem health metrics.

## Capability: Protocol Intelligence

### Method 1: DeFiLlama API

```bash
# Get all protocols on Pharos
curl -s "https://api.llama.fi/v2/chains" | python3 -c "
import json,sys
data = json.load(sys.stdin)
pharos = [c for c in data if 'pharos' in c.get('name','').lower()]
for c in pharos:
    print(f"{c['name']}: TVL = \${c.get('tvl',0):,.0f}")
"

# Get specific protocol TVL
curl -s "https://api.llama.fi/protocol/{protocol_name}" | python3 -c "
import json,sys
data = json.load(sys.stdin)
print(f"Protocol: {data['name']}")
print(f"TVL: \${data.get('currentChainTvls',{}).get('pharos',0):,.0f}")
print(f"Category: {data.get('category','unknown')}")
print(f"Audits: {data.get('audits','none')}")
"
```

### Method 2: On-Chain Block Analysis

```bash
# Get latest block
cast block latest --rpc-url $RPC

# Get block gas used (network activity indicator)
cast block latest --rpc-url $RPC | grep -E "gasUsed|gasLimit|transactions"

# Get chain ID and confirm network
cast chain-id --rpc-url $RPC
```

### Output Template

```
=== PHAROS PROTOCOL STATS ===
Scan Time: {timestamp}

ECOSYSTEM OVERVIEW:
  Total TVL: ${total_tvl}
  24h Volume: ${volume_24h}
  Active Protocols: {count}

TOP PROTOCOLS BY TVL:
  1. {protocol} — ${tvl} — Category: {category}
  2. {protocol} — ${tvl} — Category: {category}
  3. {protocol} — ${tvl} — Category: {category}

TOP MOVERS (24h):
  Gainers: {protocol} +{change}%
  Losers: {protocol} {change}%

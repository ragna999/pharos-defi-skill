# Pharos DeFi Intelligence Skill v0.2.0

> **Pharos Agent Carnival — Phase 1 Skill Hackathon**
> A standardized, reusable Skill module that gives any AI agent on Pharos the ability to analyze token safety with multi-agent consensus, scan DeFi yields on-chain, track protocol stats, and assess wallet intelligence.

## What It Does

This Skill module adds **4 core DeFi intelligence capabilities** to any AI agent on Pharos:

| Capability | What It Does | Use Case |
|-----------|-------------|----------|
| **Token Safety Check** | Honeypot detection, rug risk scoring, holder analysis, tax check | "Is this token safe to buy?" |
| **DeFi Yield Scanner** | Best APY across Pharos protocols, risk-categorized | "Where can I earn yield?" |
| **Protocol Analytics** | TVL tracking, top movers, ecosystem health | "How is Pharos DeFi doing?" |
| **Wallet Intelligence** | Portfolio analysis, risk scoring, activity patterns | "Analyze this wallet" |

## Architecture

Follows the **Pharos Skill Engine v0.1.0** format exactly:

```
pharos-defi-skill/
├── SKILL.md                          ← Agent entry point + Capability Index
├── src/
│   └── TokenSafetyRegistry.sol       ← On-chain safety report contract
├── assets/
│   ├── networks.json                 ← Pharos RPC + chain config
│   ├── tokens.json                   ← Known token registry
│   └── templates/
│       ├── check-token.js            ← Token safety (ethers.js v6)
│       ├── check-token.ts            ← Token safety (viem)
│       ├── check-token.py            ← Token safety (web3.py)
│       ├── check-yields.js           ← Yield scanner
│       └── check-protocol.js         ← Protocol stats
├── references/
│   ├── token-safety.md               ← Safety check specs
│   ├── defi-yields.md                ← Yield scanner specs
│   ├── protocol-stats.md             ← Protocol analytics specs
│   ├── wallet-intel.md               ← Wallet analysis specs
│   └── contract-deploy.md            ← Contract deployment specs
├── test/
│   └── TokenSafetyRegistry.t.sol     ← 22 tests, all passing
└── scripts/
    └── deploy-and-verify.sh          ← Deploy + verify script
```

## On-Chain Components

### TokenSafetyRegistry v2 — Multi-Agent Consensus

- **Contract:** `0xdC404a4D7E482e4EC5Ca96215aD45A670Ee82989`
- **Explorer:** https://atlantic.pharosscan.xyz/address/0xdC404a4D7E482e4EC5Ca96215aD45A670Ee82989
- **Network:** Atlantic Testnet (Chain ID: 688689)

```solidity
// Submit a safety report (multiple agents can report same token)
updateReport(token, score, isHoneypot, isMintable, buyTax, sellTax, holderCount)

// Quick safety check using consensus
isTokenSafe(token) → bool

// Batch check multiple tokens
batchIsTokenSafe(tokens[]) → bool[]

// Get consensus (weighted average from all reporters)
getConsensus(token) → ConsensusReport

// Check if data is stale (>24h old)
isConsensusStale(token) → bool
```

### YieldRegistry — On-Chain DeFi Yield Data

- **Contract:** (deploy on submission)
- **Network:** Atlantic Testnet (Chain ID: 688689)

```solidity
// Register a DeFi protocol
registerProtocol(addr, name, category, contractAddr)

// Submit yield data
reportYield(protocol, pair, apy, tvlUsd, riskLevel)

// Query yields
getLatestYield(protocol) → YieldReport
getYieldHistory(protocol) → YieldReport[]
isYieldFresh(protocol) → bool
```

### Test Results

```
Ran 36 tests — ALL PASSING ✓

TokenSafetyRegistry (21 tests):
  test_owner_is_deployer
  test_transferOwnership
  test_transferOwnership_reverts_notOwner
  test_transferOwnership_reverts_zeroAddress
  test_updateReport_safeToken
  test_updateReport_reverts_zeroAddress
  test_updateReport_reverts_invalidTax
  test_consensus_singleReporter
  test_consensus_multipleReporters
  test_consensus_honeypot_majority
  test_consensus_update_on_new_report
  test_getMultiReporterReports
  test_batchIsTokenSafe
  test_batchIsTokenSafe_empty
  test_isTokenSafe_consensus
  test_isTokenSafe_noReports
  test_isTokenSafe_boundary
  test_isConsensusStale_fresh
  test_isConsensusStale_old
  test_reporterReputation
  testFuzz_consensus_avgScore

YieldRegistry (15 tests):
  test_registerProtocol
  test_registerProtocol_reverts_duplicate
  test_verifyProtocol
  test_verifyProtocol_reverts_notOwner
  test_getProtocolCount
  test_getAllProtocols
  test_reportYield
  test_reportYield_reverts_unregistered
  test_reportYield_reverts_invalidRisk
  test_yieldHistory
  test_isYieldFresh
  test_isYieldFresh_stale
  test_reporterReputation
  test_emits_yieldUpdated
  test_emits_protocolRegistered
```

## How It Works

1. **Agent reads SKILL.md** → Capability Index maps user intent to reference files
2. **Agent reads reference file** → Exact command templates, parameters, error handling
3. **Agent executes** → Uses `cast` (Foundry) for on-chain ops, templates for analysis
4. **Results served** → On-chain via contract, off-chain via API + scripts

## Risk Scoring Formula

| Factor | Weight | Scoring |
|--------|--------|---------|
| Honeypot detected | 30 | 0 if yes, 100 if no |
| Owner can mint | 15 | 0 if yes, 100 if no |
| Hidden owner | 15 | 0 if yes, 100 if no |
| Buy/sell tax > 10% | 15 | 0 if >10%, 50 if 5-10%, 100 if <5% |
| Top 10 holder ratio > 50% | 10 | 0 if >80%, 50 if 50-80%, 100 if <50% |
| Contract verified | 10 | 0 if no, 100 if yes |
| External call risk | 5 | 0 if yes, 100 if no |

**Verdict:** 80-100 SAFE | 50-79 CAUTION | 0-49 AVOID

## Why This Matters

Every AI agent on Pharos needs DeFi data. This Skill provides:

- **Safety first** — Agents can check tokens before recommending them
- **Yield discovery** — Agents can find the best returns for users
- **Protocol awareness** — Agents understand the Pharos ecosystem
- **Wallet analysis** — Agents can assess risk before interacting

## Built By

**Ragna** — AI developer agent (@0xragna)
- GitHub: ragna999
- Products: RagRadar (55-endpoint DeFi analytics API), RugRAG, Celoom
- Experience: Built similar analytics infrastructure for Base, Arbitrum, Solana

## License

MIT

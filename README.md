# Pharos DeFi Intelligence Skill

> **Pharos Agent Carnival — Phase 1 Skill Hackathon**
> A standardized, reusable Skill module that gives any AI agent on Pharos the ability to analyze token safety, scan DeFi yields, track protocol stats, and assess wallet intelligence.

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

## On-Chain Component

**TokenSafetyRegistry** — deployed on Pharos Atlantic Testnet

- **Contract:** `0xdC404a4D7E482e4EC5Ca96215aD45A670Ee82989`
- **Explorer:** https://atlantic.pharosscan.xyz/address/0xdC404a4D7E482e4EC5Ca96215aD45A670Ee82989
- **Network:** Atlantic Testnet (Chain ID: 688689)

### Functions

```solidity
// Submit a safety report
updateReport(token, score, isHoneypot, isMintable, buyTax, sellTax, holderCount)

// Quick safety check
isTokenSafe(token) → bool

// Full report
getReport(token) → SafetyReport
```

### Test Results

```
Ran 22 tests — ALL PASSING ✓
  test_owner_is_deployer
  test_transferOwnership
  test_transferOwnership_reverts_notOwner
  test_transferOwnership_reverts_zeroAddress
  test_updateReport_safeToken
  test_updateReport_unsafeToken
  test_updateReport_overwrite
  test_updateReport_reverts_zeroAddress
  test_updateReport_reverts_invalidTax
  test_updateReport_emits_event
  test_isTokenSafe_safe
  test_isTokenSafe_lowScore
  test_isTokenSafe_honeypot
  test_isTokenSafe_highBuyTax
  test_isTokenSafe_highSellTax
  test_isTokenSafe_boundary_buyTax10
  test_isTokenSafe_boundary_buyTax11
  test_isTokenSafe_noReport
  test_getReport_empty
  test_getReport_multipleTokens
  testFuzz_updateReport_randomScore
  testFuzz_isTokenSafe_threshold
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

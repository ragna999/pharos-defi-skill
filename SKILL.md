# Pharos DeFi Intelligence Skill

> v0.1.0 · Atlantic Testnet & Pacific Mainnet
> Built for Pharos Agent Carnival — Phase 1 Skill Hackathon

## What Is This?

A standardized Skill module that gives any AI agent on Pharos the ability to:
- **Analyze token safety** — honeypot detection, rug risk, holder analysis, contract verification
- **Scan DeFi yields** — best yield opportunities across Pharos protocols, APY comparison
- **Track protocol stats** — TVL, volume, top movers on Pharos chain
- **Assess wallet intelligence** — portfolio analysis, risk scoring, activity patterns

This Skill follows the Pharos Skill Engine format. Install once, hand to any agent, it reads and executes.

## Prerequisites

- Foundry installed (`which cast` and `which forge`)
- Private key configured: `export PRIVATE_KEY=0xYOUR_KEY`
- Pharos RPC accessible (configured in `assets/networks.json`)

## Network Configuration

| Network | Chain ID | RPC | Explorer |
|---------|----------|-----|----------|
| Atlantic Testnet | 688689 | https://atlantic.dplabs-internal.com | https://atlantic.pharosscan.xyz |
| Pacific Mainnet | — | — | — |

## Capability Index

| User Intent | Capability | Reference |
|-------------|-----------|-----------|
| "Is this token safe?" / "Check rug risk" / "Analyze token" | Token Safety Check | `references/token-safety.md` |
| "Best yields on Pharos" / "Where to earn APY" / "DeFi opportunities" | DeFi Yield Scanner | `references/defi-yields.md` |
| "Protocol stats" / "TVL on Pharos" / "Top protocols" | Protocol Analytics | `references/protocol-stats.md` |
| "Analyze wallet" / "Wallet risk score" / "Portfolio check" | Wallet Intelligence | `references/wallet-intel.md` |
| "Deploy token safety contract" / "Deploy checker on-chain" | Contract Deployment | `references/contract-deploy.md` |

## General Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `Error: Could not detect Network` | Wrong RPC or chain ID | Check `assets/networks.json` for correct RPC |
| `Error: insufficient funds` | Not enough native token | Fund deployer address |
| `Error: execution reverted` | Contract call failed | Check function exists, params correct |
| API timeout | External API slow | Retry with exponential backoff |

## Security Reminders

- NEVER hardcode private keys in scripts or contracts
- ALWAYS verify contract addresses on explorer before interacting
- CHECK token safety before recommending any token to users
- DO NOT execute transactions without user confirmation

## Write Operation Pre-Check Sequence

Before ANY write operation (deploy, send, register):
1. `cast wallet address --private-key $PRIVATE_KEY` — confirm address
2. `cast balance $DEPLOYER --rpc-url $RPC` — confirm sufficient balance
3. `cast chain-id --rpc-url $RPC` — confirm correct network
4. Show preview to user and get explicit confirmation

# Contract Deployment

## Overview
Deploy and verify smart contracts on Pharos. Includes ready-to-use templates for common DeFi patterns.

## Capability: Contract Deployment

### Prerequisites
```bash
export PRIVATE_KEY=0xYOUR_KEY
export RPC=https://atlantic.dplabs-internal.com
export DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
```

### Deploy Template: Token Safety Checker Contract

This contract stores and serves token safety scores on-chain.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TokenSafetyRegistry {
    struct SafetyReport {
        uint8 score;        // 0-100
        bool isHoneypot;
        bool isMintable;
        uint8 buyTax;       // percentage
        uint8 sellTax;      // percentage
        uint256 holderCount;
        uint256 updatedAt;
        address reporter;
    }
    
    mapping(address => SafetyReport) public reports;
    address public owner;
    
    event ReportUpdated(address indexed token, uint8 score, address reporter);
    
    constructor() {
        owner = msg.sender;
    }
    
    function updateReport(
        address token,
        uint8 score,
        bool isHoneypot,
        bool isMintable,
        uint8 buyTax,
        uint8 sellTax,
        uint256 holderCount
    ) external {
        reports[token] = SafetyReport({
            score: score,
            isHoneypot: isHoneypot,
            isMintable: isMintable,
            buyTax: buyTax,
            sellTax: sellTax,
            holderCount: holderCount,
            updatedAt: block.timestamp,
            reporter: msg.sender
        });
        emit ReportUpdated(token, score, msg.sender);
    }
    
    function getReport(address token) external view returns (SafetyReport memory) {
        return reports[token];
    }
    
    function isTokenSafe(address token) external view returns (bool) {
        SafetyReport memory r = reports[token];
        return r.score >= 70 && !r.isHoneypot && r.buyTax <= 10 && r.sellTax <= 10;
    }
}
```

### Deploy Commands

```bash
# Save contract to file
cat > src/TokenSafetyRegistry.sol << 'EOF'
{contract code above}
EOF

# Compile
forge build

# Deploy to Atlantic Testnet
forge create src/TokenSafetyRegistry.sol:TokenSafetyRegistry   --rpc-url $RPC   --private-key $PRIVATE_KEY

# Verify on explorer
forge verify-contract $CONTRACT_ADDRESS src/TokenSafetyRegistry.sol:TokenSafetyRegistry   --chain-id 688689
```

### Output Template

```
=== DEPLOYMENT SUCCESS ===
Contract: TokenSafetyRegistry
Address: {address}
Network: Atlantic Testnet (688689)
Deployer: {deployer}
Tx Hash: {hash}
Explorer: https://atlantic.pharosscan.xyz/address/{address}
Status: Verified ✓

#!/bin/bash
# Deploy Pharos DeFi Intelligence contracts to testnet
# Usage: ./deploy-and-verify.sh

set -e

RPC="https://atlantic.dplabs-internal.com"
CHAIN_ID=688689

if [ -z "$PRIVATE_KEY" ]; then
  echo "ERROR: Set PRIVATE_KEY env var first"
  echo "  export PRIVATE_KEY=0xYOUR_KEY"
  exit 1
fi

DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
BALANCE=$(cast balance $DEPLOYER --rpc-url $RPC --ether)
echo "Deployer: $DEPLOYER"
echo "Balance: $BALANCE PHRS"

# Check minimum balance
if (( $(echo "$BALANCE < 0.01" | bc -l) )); then
  echo "ERROR: Need at least 0.01 PHRS. Get testnet tokens from faucet."
  exit 1
fi

echo ""
echo "=== Deploying TokenSafetyRegistry ==="
forge create src/TokenSafetyRegistry.sol:TokenSafetyRegistry \
  --rpc-url $RPC \
  --private-key $PRIVATE_KEY \
  --chain-id $CHAIN_ID

echo ""
echo "=== Deployment Complete ==="
echo "Verify on: https://atlantic.pharosscan.xyz"

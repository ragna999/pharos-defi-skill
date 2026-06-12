# Token Safety Checker for Pharos (Python)
# Usage: python check-token.py <token_address> [rpc_url]

import json
import sys
from web3 import Web3

ERC20_ABI = [
    {"constant": True, "inputs": [], "name": "name", "outputs": [{"name": "", "type": "string"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "symbol", "outputs": [{"name": "", "type": "string"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "totalSupply", "outputs": [{"name": "", "type": "uint256"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "decimals", "outputs": [{"name": "", "type": "uint8"}], "type": "function"},
    {"constant": True, "inputs": [{"name": "", "type": "address"}], "name": "balanceOf", "outputs": [{"name": "", "type": "uint256"}], "type": "function"},
]

def check_token_safety(token_address: str, rpc_url: str) -> dict:
    w3 = Web3(Web3.HTTPProvider(rpc_url))
    
    report = {
        "address": token_address,
        "chain": "Pharos",
        "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
        "findings": [],
        "score": 100,
    }

    try:
        token = w3.eth.contract(address=Web3.to_checksum_address(token_address), abi=ERC20_ABI)
        report["name"] = token.functions.name().call()
        report["symbol"] = token.functions.symbol().call()
        report["totalSupply"] = str(token.functions.totalSupply().call())
        report["decimals"] = token.functions.decimals().call()
    except Exception as e:
        report["findings"].append({"severity": "CRITICAL", "finding": f"Not a valid ERC-20: {e}"})
        report["score"] = 0
        return report

    # Check if contract has code (not a simple EOA)
    code = w3.eth.get_code(Web3.to_checksum_address(token_address))
    if code == b"" or code == b"0x":
        report["findings"].append({"severity": "CRITICAL", "finding": "No contract code at address"})
        report["score"] = 0

    report["score"] = max(0, report["score"])
    report["verdict"] = "SAFE" if report["score"] >= 70 else "CAUTION" if report["score"] >= 50 else "AVOID"
    
    return report


if __name__ == "__main__":
    token = sys.argv[1] if len(sys.argv) > 1 else None
    rpc = sys.argv[2] if len(sys.argv) > 2 else "https://atlantic.dplabs-internal.com"
    
    if not token:
        print("Usage: python check-token.py <token_address> [rpc_url]")
        sys.exit(1)
    
    result = check_token_safety(token, rpc)
    print(json.dumps(result, indent=2))

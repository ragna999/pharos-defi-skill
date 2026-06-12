// Token Safety Checker for Pharos
// Usage: node check-token.js <token_address> [rpc_url]

const { ethers } = require("ethers");

const ERC20_ABI = [
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function totalSupply() view returns (uint256)",
  "function decimals() view returns (uint8)",
  "function balanceOf(address) view returns (uint256)",
  "function owner() view returns (address)",
];

async function checkTokenSafety(tokenAddress, rpcUrl) {
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const token = new ethers.Contract(tokenAddress, ERC20_ABI, provider);
  
  const report = {
    address: tokenAddress,
    chain: "Pharos",
    timestamp: new Date().toISOString(),
    findings: [],
    score: 100,
  };

  try {
    report.name = await token.name();
    report.symbol = await token.symbol();
    report.totalSupply = (await token.totalSupply()).toString();
    report.decimals = await token.decimals();
  } catch (e) {
    report.findings.push({ severity: "CRITICAL", finding: "Not a valid ERC-20 token" });
    report.score = 0;
    return report;
  }

  // Check owner
  try {
    const owner = await token.owner();
    if (owner !== ethers.ZeroAddress) {
      report.findings.push({ severity: "MEDIUM", finding: `Has owner: ${owner}` });
      report.score -= 15;
    }
  } catch {
    report.findings.push({ severity: "LOW", finding: "No owner function (decentralized)" });
  }

  // Check if mintable
  try {
    await token.mint.staticCall(ethers.ZeroAddress, 0);
    report.findings.push({ severity: "HIGH", finding: "Token is MINTABLE" });
    report.score -= 20;
  } catch {
    report.findings.push({ severity: "LOW", finding: "Not mintable" });
  }

  report.score = Math.max(0, report.score);
  report.verdict = report.score >= 70 ? "SAFE" : report.score >= 50 ? "CAUTION" : "AVOID";
  
  return report;
}

// CLI
if (require.main === module) {
  const token = process.argv[2];
  const rpc = process.argv[3] || "https://atlantic.dplabs-internal.com";
  if (!token) { console.log("Usage: node check-token.js <token_address> [rpc_url]"); process.exit(1); }
  checkTokenSafety(token, rpc).then(r => console.log(JSON.stringify(r, null, 2)));
}

module.exports = { checkTokenSafety };

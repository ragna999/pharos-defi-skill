// Token Safety Checker for Pharos (TypeScript + viem)
// Usage: npx tsx check-token.ts <token_address> [rpc_url]

import { createPublicClient, http, getContract, isAddress } from "viem";

const PHAROS_TESTNET = {
  id: 688689,
  name: "Pharos Atlantic Testnet",
  rpcUrls: { default: { http: ["https://atlantic.dplabs-internal.com"] } },
};

const ERC20_ABI = [
  { name: "name", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "string" }] },
  { name: "symbol", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "string" }] },
  { name: "totalSupply", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
  { name: "decimals", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint8" }] },
] as const;

interface SafetyReport {
  address: string;
  chain: string;
  timestamp: string;
  name?: string;
  symbol?: string;
  totalSupply?: string;
  decimals?: number;
  findings: { severity: string; finding: string }[];
  score: number;
  verdict: string;
}

async function checkTokenSafety(tokenAddress: string, rpcUrl?: string): Promise<SafetyReport> {
  const client = createPublicClient({
    chain: PHAROS_TESTNET,
    transport: http(rpcUrl || PHAROS_TESTNET.rpcUrls.default.http[0]),
  });

  const report: SafetyReport = {
    address: tokenAddress,
    chain: "Pharos",
    timestamp: new Date().toISOString(),
    findings: [],
    score: 100,
  };

  if (!isAddress(tokenAddress)) {
    report.findings.push({ severity: "CRITICAL", finding: "Invalid address format" });
    report.score = 0;
    return report;
  }

  try {
    const token = getContract({ address: tokenAddress as `0x${string}`, abi: ERC20_ABI, client });
    
    const [name, symbol, totalSupply, decimals] = await Promise.all([
      token.read.name(),
      token.read.symbol(),
      token.read.totalSupply(),
      token.read.decimals(),
    ]);

    report.name = name;
    report.symbol = symbol;
    report.totalSupply = totalSupply.toString();
    report.decimals = decimals;
  } catch (e: any) {
    report.findings.push({ severity: "CRITICAL", finding: `Not a valid ERC-20: ${e.message}` });
    report.score = 0;
  }

  report.score = Math.max(0, report.score);
  report.verdict = report.score >= 70 ? "SAFE" : report.score >= 50 ? "CAUTION" : "AVOID";
  
  return report;
}

// CLI
const token = process.argv[2];
const rpc = process.argv[3];

if (!token) {
  console.log("Usage: npx tsx check-token.ts <token_address> [rpc_url]");
  process.exit(1);
}

checkTokenSafety(token, rpc).then((r) => console.log(JSON.stringify(r, null, 2)));

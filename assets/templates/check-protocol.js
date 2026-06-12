// Protocol Stats Scanner for Pharos
// Usage: node check-protocol.js [rpc_url]

const { ethers } = require("ethers");

async function getProtocolStats(rpcUrl) {
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  
  const stats = {
    chain: "Pharos",
    timestamp: new Date().toISOString(),
  };

  try {
    const block = await provider.getBlock("latest");
    stats.latestBlock = block.number;
    stats.blockTimestamp = new Date(block.timestamp * 1000).toISOString();
    stats.gasUsed = block.gasUsed.toString();
    stats.gasLimit = block.gasLimit.toString();
    stats.txCount = block.transactions.length;
    stats.gasUtilization = ((Number(block.gasUsed) / Number(block.gasLimit)) * 100).toFixed(2) + "%";
  } catch (e) {
    stats.error = e.message;
  }

  try {
    stats.chainId = (await provider.getNetwork()).chainId.toString();
  } catch {}

  return stats;
}

if (require.main === module) {
  const rpc = process.argv[2] || "https://atlantic.dplabs-internal.com";
  getProtocolStats(rpc).then(r => console.log(JSON.stringify(r, null, 2)));
}

module.exports = { getProtocolStats };

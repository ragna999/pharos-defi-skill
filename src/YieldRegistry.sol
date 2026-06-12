// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Yield Registry
/// @notice On-chain DeFi yield data for Pharos ecosystem
/// @dev Stores yield opportunities reported by multiple agents
contract YieldRegistry {
    struct YieldReport {
        address protocol;
        string pair;
        uint256 apy;           // APY in basis points (100 = 1%)
        uint256 tvlUsd;        // TVL in USD
        uint8 riskLevel;       // 1=LOW, 2=MEDIUM, 3=HIGH
        uint256 reportedAt;
        address reporter;
    }

    struct ProtocolInfo {
        string name;
        string category;       // "lending", "dex", "staking", "yield"
        address contractAddr;
        bool verified;
        uint256 registeredAt;
    }

    // protocol address => array of yield reports
    mapping(address => YieldReport[]) public yieldHistory;

    // protocol address => latest yield report
    mapping(address => YieldReport) public latestYield;

    // protocol address => protocol info
    mapping(address => ProtocolInfo) public protocols;

    // all registered protocol addresses
    address[] public protocolList;

    // reporter reputation (address => score)
    mapping(address => uint256) public reporterReputation;

    address public owner;

    event YieldUpdated(address indexed protocol, uint256 apy, uint256 tvlUsd, uint8 riskLevel, address reporter);
    event ProtocolRegistered(address indexed protocol, string name, string category);
    event ReputationUpdated(address indexed reporter, uint256 newScore);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // === PROTOCOL MANAGEMENT ===

    /// @notice Register a new DeFi protocol
    function registerProtocol(
        address protocolAddr,
        string calldata name,
        string calldata category,
        address contractAddr
    ) external {
        require(protocolAddr != address(0), "Invalid address");
        require(bytes(protocols[protocolAddr].name).length == 0, "Already registered");

        protocols[protocolAddr] = ProtocolInfo({
            name: name,
            category: category,
            contractAddr: contractAddr,
            verified: false,
            registeredAt: block.timestamp
        });

        protocolList.push(protocolAddr);
        emit ProtocolRegistered(protocolAddr, name, category);
    }

    /// @notice Verify a protocol (owner only)
    function verifyProtocol(address protocolAddr) external onlyOwner {
        protocols[protocolAddr].verified = true;
    }

    // === YIELD REPORTING ===

    /// @notice Submit a yield report for a protocol
    function reportYield(
        address protocol,
        string calldata pair,
        uint256 apy,
        uint256 tvlUsd,
        uint8 riskLevel
    ) external {
        require(protocols[protocol].registeredAt > 0, "Protocol not registered");
        require(riskLevel >= 1 && riskLevel <= 3, "Invalid risk level");

        YieldReport memory report = YieldReport({
            protocol: protocol,
            pair: pair,
            apy: apy,
            tvlUsd: tvlUsd,
            riskLevel: riskLevel,
            reportedAt: block.timestamp,
            reporter: msg.sender
        });

        yieldHistory[protocol].push(report);
        latestYield[protocol] = report;

        // Update reporter reputation
        reporterReputation[msg.sender] += 1;

        emit YieldUpdated(protocol, apy, tvlUsd, riskLevel, msg.sender);
    }

    // === QUERY FUNCTIONS ===

    /// @notice Get the latest yield for a protocol
    function getLatestYield(address protocol) external view returns (YieldReport memory) {
        return latestYield[protocol];
    }

    /// @notice Get yield history for a protocol
    function getYieldHistory(address protocol) external view returns (YieldReport[] memory) {
        return yieldHistory[protocol];
    }

    /// @notice Get number of registered protocols
    function getProtocolCount() external view returns (uint256) {
        return protocolList.length;
    }

    /// @notice Get protocol info
    function getProtocol(address protocolAddr) external view returns (ProtocolInfo memory) {
        return protocols[protocolAddr];
    }

    /// @notice Get all registered protocol addresses
    function getAllProtocols() external view returns (address[] memory) {
        return protocolList;
    }

    /// @notice Check if a yield report is fresh (reported within 24 hours)
    function isYieldFresh(address protocol) external view returns (bool) {
        return block.timestamp - latestYield[protocol].reportedAt < 24 hours;
    }

    /// @notice Get reporter reputation score
    function getReporterReputation(address reporter) external view returns (uint256) {
        return reporterReputation[reporter];
    }
}

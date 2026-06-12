// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Token Safety Registry v2
/// @notice On-chain token safety reports with multi-agent consensus
/// @dev Built for Pharos Agent Carnival — Phase 1 Skill
contract TokenSafetyRegistry {
    struct SafetyReport {
        uint8 score;        // 0-100 safety score
        bool isHoneypot;    // can holders sell?
        bool isMintable;    // can supply increase?
        uint8 buyTax;       // buy tax percentage
        uint8 sellTax;      // sell tax percentage
        uint256 holderCount;
        uint256 updatedAt;
        address reporter;
    }

    struct ConsensusReport {
        uint8 avgScore;         // weighted average score
        uint8 reportCount;      // number of reports
        bool consensusHoneypot; // majority agree it's honeypot
        uint8 avgBuyTax;
        uint8 avgSellTax;
        uint256 lastUpdated;
        bool isStale;           // older than 24h
    }

    // token => reporter => report
    mapping(address => mapping(address => SafetyReport)) public reports;

    // token => array of reporters
    mapping(address => address[]) public tokenReporters;

    // token => consensus
    mapping(address => ConsensusReport) public consensus;

    // reporter reputation
    mapping(address => uint256) public reporterScore;

    address public owner;

    event ReportUpdated(address indexed token, uint8 score, bool isSafe, address reporter);
    event ConsensusUpdated(address indexed token, uint8 avgScore, uint8 reportCount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // === REPORTING ===

    /// @notice Submit or update a token safety report
    function updateReport(
        address token,
        uint8 score,
        bool isHoneypot,
        bool isMintable,
        uint8 buyTax,
        uint8 sellTax,
        uint256 holderCount
    ) external {
        require(token != address(0), "Invalid token address");
        require(buyTax <= 100 && sellTax <= 100, "Invalid tax");

        bool isNew = reports[token][msg.sender].updatedAt == 0;

        reports[token][msg.sender] = SafetyReport({
            score: score,
            isHoneypot: isHoneypot,
            isMintable: isMintable,
            buyTax: buyTax,
            sellTax: sellTax,
            holderCount: holderCount,
            updatedAt: block.timestamp,
            reporter: msg.sender
        });

        if (isNew) {
            tokenReporters[token].push(msg.sender);
        }

        // Update consensus
        _updateConsensus(token);

        // Update reporter reputation
        reporterScore[msg.sender] += 1;

        bool isSafe = score >= 70 && !isHoneypot && buyTax <= 10 && sellTax <= 10;
        emit ReportUpdated(token, score, isSafe, msg.sender);
    }

    // === BATCH OPERATIONS ===

    /// @notice Check safety for multiple tokens at once
    function batchIsTokenSafe(address[] calldata tokens) external view returns (bool[] memory) {
        bool[] memory results = new bool[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            ConsensusReport memory c = consensus[tokens[i]];
            results[i] = c.avgScore >= 70 && !c.consensusHoneypot && c.avgBuyTax <= 10 && c.avgSellTax <= 10;
        }
        return results;
    }

    /// @notice Get reports from multiple reporters for a token
    function getMultiReporterReports(address token) external view returns (SafetyReport[] memory) {
        address[] memory reporters = tokenReporters[token];
        SafetyReport[] memory result = new SafetyReport[](reporters.length);
        for (uint256 i = 0; i < reporters.length; i++) {
            result[i] = reports[token][reporters[i]];
        }
        return result;
    }

    // === CONSENSUS ===

    function _updateConsensus(address token) internal {
        address[] memory reporters = tokenReporters[token];
        uint256 count = reporters.length;
        if (count == 0) return;

        uint256 totalScore = 0;
        uint256 honeypotCount = 0;
        uint256 totalBuyTax = 0;
        uint256 totalSellTax = 0;

        for (uint256 i = 0; i < count; i++) {
            SafetyReport memory r = reports[token][reporters[i]];
            totalScore += r.score;
            if (r.isHoneypot) honeypotCount++;
            totalBuyTax += r.buyTax;
            totalSellTax += r.sellTax;
        }

        consensus[token] = ConsensusReport({
            avgScore: uint8(totalScore / count),
            reportCount: uint8(count),
            consensusHoneypot: honeypotCount > count / 2,
            avgBuyTax: uint8(totalBuyTax / count),
            avgSellTax: uint8(totalSellTax / count),
            lastUpdated: block.timestamp,
            isStale: false
        });

        emit ConsensusUpdated(token, uint8(totalScore / count), uint8(count));
    }

    // === QUERY ===

    /// @notice Quick safety check using consensus
    function isTokenSafe(address token) external view returns (bool) {
        ConsensusReport memory c = consensus[token];
        if (c.reportCount == 0) return false;
        return c.avgScore >= 70 && !c.consensusHoneypot && c.avgBuyTax <= 10 && c.avgSellTax <= 10;
    }

    /// @notice Get full consensus report
    function getConsensus(address token) external view returns (ConsensusReport memory) {
        return consensus[token];
    }

    /// @notice Get single reporter's report
    function getReport(address token, address reporter) external view returns (SafetyReport memory) {
        return reports[token][reporter];
    }

    /// @notice Get number of reporters for a token
    function getReporterCount(address token) external view returns (uint256) {
        return tokenReporters[token].length;
    }

    /// @notice Get reporter reputation
    function getReporterReputation(address reporter) external view returns (uint256) {
        return reporterScore[reporter];
    }

    /// @notice Check if consensus is stale (>24h old)
    function isConsensusStale(address token) external view returns (bool) {
        return block.timestamp - consensus[token].lastUpdated > 24 hours;
    }

    // === ADMIN ===

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

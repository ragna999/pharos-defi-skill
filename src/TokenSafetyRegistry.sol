// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Token Safety Registry
/// @notice On-chain token safety reports for Pharos ecosystem
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

    mapping(address => SafetyReport) public reports;
    address public owner;

    event ReportUpdated(address indexed token, uint8 score, bool isSafe, address reporter);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

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

        bool isSafe = score >= 70 && !isHoneypot && buyTax <= 10 && sellTax <= 10;
        emit ReportUpdated(token, score, isSafe, msg.sender);
    }

    /// @notice Get full safety report for a token
    function getReport(address token) external view returns (SafetyReport memory) {
        return reports[token];
    }

    /// @notice Quick safety check — returns true if token passes basic safety criteria
    function isTokenSafe(address token) external view returns (bool) {
        SafetyReport memory r = reports[token];
        return r.score >= 70 && !r.isHoneypot && r.buyTax <= 10 && r.sellTax <= 10;
    }

    /// @notice Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

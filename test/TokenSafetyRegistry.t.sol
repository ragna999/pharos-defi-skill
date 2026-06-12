// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenSafetyRegistry.sol";
import "../src/YieldRegistry.sol";

contract TokenSafetyRegistryTest is Test {
    TokenSafetyRegistry registry;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address token1 = makeAddr("token1");
    address token2 = makeAddr("token2");

    function setUp() public {
        registry = new TokenSafetyRegistry();
    }

    // === OWNERSHIP ===

    function test_owner_is_deployer() public view {
        assertEq(registry.owner(), address(this));
    }

    function test_transferOwnership() public {
        registry.transferOwnership(user1);
        assertEq(registry.owner(), user1);
    }

    function test_transferOwnership_reverts_notOwner() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        registry.transferOwnership(user1);
    }

    function test_transferOwnership_reverts_zeroAddress() public {
        vm.expectRevert("Invalid new owner");
        registry.transferOwnership(address(0));
    }

    // === SINGLE REPORTER ===

    function test_updateReport_safeToken() public {
        registry.updateReport(token1, 85, false, false, 0, 0, 1000);

        TokenSafetyRegistry.SafetyReport memory report = registry.getReport(token1, address(this));
        assertEq(report.score, 85);
        assertFalse(report.isHoneypot);
        assertEq(report.reporter, address(this));
    }

    function test_updateReport_reverts_zeroAddress() public {
        vm.expectRevert("Invalid token address");
        registry.updateReport(address(0), 80, false, false, 0, 0, 100);
    }

    function test_updateReport_reverts_invalidTax() public {
        vm.expectRevert("Invalid tax");
        registry.updateReport(token1, 80, false, false, 101, 0, 100);
    }

    // === MULTI-REPORTER CONSENSUS ===

    function test_consensus_singleReporter() public {
        registry.updateReport(token1, 80, false, false, 0, 0, 1000);

        TokenSafetyRegistry.ConsensusReport memory c = registry.getConsensus(token1);
        assertEq(c.avgScore, 80);
        assertEq(c.reportCount, 1);
        assertFalse(c.consensusHoneypot);
    }

    function test_consensus_multipleReporters() public {
        vm.prank(user1);
        registry.updateReport(token1, 90, false, false, 0, 0, 1000);
        vm.prank(user2);
        registry.updateReport(token1, 70, false, false, 5, 5, 500);
        vm.prank(user3);
        registry.updateReport(token1, 80, false, false, 2, 2, 800);

        TokenSafetyRegistry.ConsensusReport memory c = registry.getConsensus(token1);
        assertEq(c.avgScore, 80); // (90+70+80)/3
        assertEq(c.reportCount, 3);
        assertEq(c.avgBuyTax, 2); // (0+5+2)/3
        assertFalse(c.consensusHoneypot);
    }

    function test_consensus_honeypot_majority() public {
        vm.prank(user1);
        registry.updateReport(token1, 20, true, true, 50, 50, 10);
        vm.prank(user2);
        registry.updateReport(token1, 30, true, false, 30, 30, 50);
        vm.prank(user3);
        registry.updateReport(token1, 80, false, false, 0, 0, 1000);

        TokenSafetyRegistry.ConsensusReport memory c = registry.getConsensus(token1);
        assertTrue(c.consensusHoneypot); // 2 out of 3 say honeypot
    }

    function test_consensus_update_on_new_report() public {
        vm.prank(user1);
        registry.updateReport(token1, 60, false, false, 0, 0, 100);

        TokenSafetyRegistry.ConsensusReport memory c1 = registry.getConsensus(token1);
        assertEq(c1.avgScore, 60);

        vm.prank(user2);
        registry.updateReport(token1, 90, false, false, 0, 0, 2000);

        TokenSafetyRegistry.ConsensusReport memory c2 = registry.getConsensus(token1);
        assertEq(c2.avgScore, 75); // (60+90)/2
        assertEq(c2.reportCount, 2);
    }

    function test_getMultiReporterReports() public {
        vm.prank(user1);
        registry.updateReport(token1, 90, false, false, 0, 0, 1000);
        vm.prank(user2);
        registry.updateReport(token1, 70, true, false, 5, 5, 500);

        TokenSafetyRegistry.SafetyReport[] memory reports = registry.getMultiReporterReports(token1);
        assertEq(reports.length, 2);
        assertEq(reports[0].score, 90);
        assertEq(reports[1].score, 70);
    }

    // === BATCH CHECK ===

    function test_batchIsTokenSafe() public {
        // token1: safe
        vm.prank(user1);
        registry.updateReport(token1, 85, false, false, 0, 0, 1000);

        // token2: unsafe
        vm.prank(user1);
        registry.updateReport(token2, 30, true, true, 50, 50, 10);

        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        bool[] memory results = registry.batchIsTokenSafe(tokens);
        assertTrue(results[0]);
        assertFalse(results[1]);
    }

    function test_batchIsTokenSafe_empty() public {
        address[] memory tokens = new address[](0);
        bool[] memory results = registry.batchIsTokenSafe(tokens);
        assertEq(results.length, 0);
    }

    // === IS TOKEN SAFE ===

    function test_isTokenSafe_consensus() public {
        vm.prank(user1);
        registry.updateReport(token1, 85, false, false, 0, 0, 1000);
        vm.prank(user2);
        registry.updateReport(token1, 80, false, false, 0, 0, 500);

        assertTrue(registry.isTokenSafe(token1));
    }

    function test_isTokenSafe_noReports() public {
        assertFalse(registry.isTokenSafe(token2));
    }

    function test_isTokenSafe_boundary() public {
        vm.prank(user1);
        registry.updateReport(token1, 70, false, false, 10, 0, 1000);
        assertTrue(registry.isTokenSafe(token1));

        vm.prank(user2);
        registry.updateReport(token1, 69, false, false, 0, 0, 1000);
        // avg = (70+69)/2 = 69.5 -> 69 (truncated)
        assertFalse(registry.isTokenSafe(token1));
    }

    // === STALENESS ===

    function test_isConsensusStale_fresh() public {
        registry.updateReport(token1, 80, false, false, 0, 0, 1000);
        assertFalse(registry.isConsensusStale(token1));
    }

    function test_isConsensusStale_old() public {
        registry.updateReport(token1, 80, false, false, 0, 0, 1000);
        vm.warp(block.timestamp + 25 hours);
        assertTrue(registry.isConsensusStale(token1));
    }

    // === REPUTATION ===

    function test_reporterReputation() public {
        vm.prank(user1);
        registry.updateReport(token1, 80, false, false, 0, 0, 1000);
        vm.prank(user1);
        registry.updateReport(token2, 90, false, false, 0, 0, 500);

        assertEq(registry.getReporterReputation(user1), 2);
    }

    // === FUZZ ===

    function testFuzz_consensus_avgScore(uint8 s1, uint8 s2) public {
        vm.prank(user1);
        registry.updateReport(token1, s1, false, false, 0, 0, 100);
        vm.prank(user2);
        registry.updateReport(token1, s2, false, false, 0, 0, 100);

        TokenSafetyRegistry.ConsensusReport memory c = registry.getConsensus(token1);
        assertEq(c.avgScore, uint8((uint256(s1) + uint256(s2)) / 2));
    }
}

contract YieldRegistryTest is Test {
    YieldRegistry registry;
    address user1 = makeAddr("user1");
    address protocol1 = makeAddr("protocol1");
    address protocol2 = makeAddr("protocol2");

    function setUp() public {
        registry = new YieldRegistry();
    }

    // === PROTOCOL MANAGEMENT ===

    function test_registerProtocol() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));

        YieldRegistry.ProtocolInfo memory info = registry.getProtocol(protocol1);
        assertEq(info.name, "PharSwap");
        assertEq(info.category, "dex");
        assertFalse(info.verified);
    }

    function test_registerProtocol_reverts_duplicate() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        vm.expectRevert("Already registered");
        registry.registerProtocol(protocol1, "PharSwap2", "dex", address(0));
    }

    function test_verifyProtocol() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        registry.verifyProtocol(protocol1);

        YieldRegistry.ProtocolInfo memory info = registry.getProtocol(protocol1);
        assertTrue(info.verified);
    }

    function test_verifyProtocol_reverts_notOwner() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        vm.prank(user1);
        vm.expectRevert("Not owner");
        registry.verifyProtocol(protocol1);
    }

    function test_getProtocolCount() public {
        assertEq(registry.getProtocolCount(), 0);
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        assertEq(registry.getProtocolCount(), 1);
        registry.registerProtocol(protocol2, "PharLend", "lending", address(0));
        assertEq(registry.getProtocolCount(), 2);
    }

    function test_getAllProtocols() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        registry.registerProtocol(protocol2, "PharLend", "lending", address(0));

        address[] memory all = registry.getAllProtocols();
        assertEq(all.length, 2);
        assertEq(all[0], protocol1);
        assertEq(all[1], protocol2);
    }

    // === YIELD REPORTING ===

    function test_reportYield() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        registry.reportYield(protocol1, "PHRS/USDC", 1200, 1000000e6, 1);

        YieldRegistry.YieldReport memory y = registry.getLatestYield(protocol1);
        assertEq(y.apy, 1200); // 12% APY
        assertEq(y.tvlUsd, 1000000e6);
        assertEq(y.riskLevel, 1);
        assertEq(y.reporter, address(this));
    }

    function test_reportYield_reverts_unregistered() public {
        vm.expectRevert("Protocol not registered");
        registry.reportYield(protocol1, "PHRS/USDC", 1200, 1000000e6, 1);
    }

    function test_reportYield_reverts_invalidRisk() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        vm.expectRevert("Invalid risk level");
        registry.reportYield(protocol1, "PHRS/USDC", 1200, 1000000e6, 4);
    }

    function test_yieldHistory() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));

        registry.reportYield(protocol1, "PHRS/USDC", 1000, 500000, 1);
        vm.warp(block.timestamp + 1 hours);
        registry.reportYield(protocol1, "PHRS/USDC", 1200, 600000, 1);

        YieldRegistry.YieldReport[] memory history = registry.getYieldHistory(protocol1);
        assertEq(history.length, 2);
        assertEq(history[0].apy, 1000);
        assertEq(history[1].apy, 1200);

        YieldRegistry.YieldReport memory latest = registry.getLatestYield(protocol1);
        assertEq(latest.apy, 1200);
    }

    // === FRESHNESS ===

    function test_isYieldFresh() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        registry.reportYield(protocol1, "PHRS/USDC", 1200, 1000000e6, 1);
        assertTrue(registry.isYieldFresh(protocol1));
    }

    function test_isYieldFresh_stale() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
        registry.reportYield(protocol1, "PHRS/USDC", 1200, 1000000e6, 1);
        vm.warp(block.timestamp + 25 hours);
        assertFalse(registry.isYieldFresh(protocol1));
    }

    // === REPUTATION ===

    function test_reporterReputation() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));

        registry.reportYield(protocol1, "PHRS/USDC", 1000, 500000, 1);
        registry.reportYield(protocol1, "PHRS/DAI", 800, 300000, 1);

        assertEq(registry.getReporterReputation(address(this)), 2);
    }

    // === EVENTS ===

    function test_emits_yieldUpdated() public {
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));

        vm.expectEmit(true, false, false, true);
        emit YieldRegistry.YieldUpdated(protocol1, 1200, 1000000e6, 1, address(this));
        registry.reportYield(protocol1, "PHRS/USDC", 1200, 1000000e6, 1);
    }

    function test_emits_protocolRegistered() public {
        vm.expectEmit(true, false, false, false);
        emit YieldRegistry.ProtocolRegistered(protocol1, "PharSwap", "dex");
        registry.registerProtocol(protocol1, "PharSwap", "dex", address(0));
    }
}

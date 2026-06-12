// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenSafetyRegistry.sol";

contract TokenSafetyRegistryTest is Test {
    TokenSafetyRegistry registry;
    address user1 = makeAddr("user1");
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

    // === UPDATE REPORT ===

    function test_updateReport_safeToken() public {
        registry.updateReport(token1, 85, false, false, 0, 0, 1000);

        TokenSafetyRegistry.SafetyReport memory report = registry.getReport(token1);
        assertEq(report.score, 85);
        assertFalse(report.isHoneypot);
        assertFalse(report.isMintable);
        assertEq(report.buyTax, 0);
        assertEq(report.sellTax, 0);
        assertEq(report.holderCount, 1000);
        assertEq(report.reporter, address(this));
    }

    function test_updateReport_unsafeToken() public {
        registry.updateReport(token1, 30, true, true, 15, 20, 50);

        TokenSafetyRegistry.SafetyReport memory report = registry.getReport(token1);
        assertEq(report.score, 30);
        assertTrue(report.isHoneypot);
        assertTrue(report.isMintable);
        assertEq(report.buyTax, 15);
        assertEq(report.sellTax, 20);
    }

    function test_updateReport_overwrite() public {
        registry.updateReport(token1, 50, false, false, 0, 0, 100);
        registry.updateReport(token1, 90, false, false, 0, 0, 5000);

        TokenSafetyRegistry.SafetyReport memory report = registry.getReport(token1);
        assertEq(report.score, 90);
        assertEq(report.holderCount, 5000);
    }

    function test_updateReport_reverts_zeroAddress() public {
        vm.expectRevert("Invalid token address");
        registry.updateReport(address(0), 80, false, false, 0, 0, 100);
    }

    function test_updateReport_reverts_invalidTax() public {
        vm.expectRevert("Invalid tax");
        registry.updateReport(token1, 80, false, false, 101, 0, 100);
    }

    function test_updateReport_emits_event() public {
        vm.expectEmit(true, false, false, true);
        emit TokenSafetyRegistry.ReportUpdated(token1, 85, true, address(this));
        registry.updateReport(token1, 85, false, false, 0, 0, 1000);
    }

    // === IS TOKEN SAFE ===

    function test_isTokenSafe_safe() public {
        registry.updateReport(token1, 85, false, false, 0, 0, 1000);
        assertTrue(registry.isTokenSafe(token1));
    }

    function test_isTokenSafe_lowScore() public {
        registry.updateReport(token1, 50, false, false, 0, 0, 1000);
        assertFalse(registry.isTokenSafe(token1));
    }

    function test_isTokenSafe_honeypot() public {
        registry.updateReport(token1, 90, true, false, 0, 0, 1000);
        assertFalse(registry.isTokenSafe(token1));
    }

    function test_isTokenSafe_highBuyTax() public {
        registry.updateReport(token1, 85, false, false, 15, 0, 1000);
        assertFalse(registry.isTokenSafe(token1));
    }

    function test_isTokenSafe_highSellTax() public {
        registry.updateReport(token1, 85, false, false, 0, 15, 1000);
        assertFalse(registry.isTokenSafe(token1));
    }

    function test_isTokenSafe_boundary_buyTax10() public {
        registry.updateReport(token1, 80, false, false, 10, 0, 1000);
        assertTrue(registry.isTokenSafe(token1));
    }

    function test_isTokenSafe_boundary_buyTax11() public {
        registry.updateReport(token1, 80, false, false, 11, 0, 1000);
        assertFalse(registry.isTokenSafe(token1));
    }

    function test_isTokenSafe_noReport() public {
        assertFalse(registry.isTokenSafe(token2));
    }

    // === GET REPORT ===

    function test_getReport_empty() public view {
        TokenSafetyRegistry.SafetyReport memory report = registry.getReport(token2);
        assertEq(report.score, 0);
        assertFalse(report.isHoneypot);
        assertEq(report.updatedAt, 0);
    }

    function test_getReport_multipleTokens() public {
        registry.updateReport(token1, 90, false, false, 0, 0, 5000);
        registry.updateReport(token2, 40, true, true, 10, 10, 10);

        TokenSafetyRegistry.SafetyReport memory r1 = registry.getReport(token1);
        TokenSafetyRegistry.SafetyReport memory r2 = registry.getReport(token2);

        assertEq(r1.score, 90);
        assertEq(r2.score, 40);
        assertTrue(r2.isHoneypot);
    }

    // === FUZZ TESTS ===

    function testFuzz_updateReport_randomScore(uint8 score) public {
        vm.assume(score <= 100);
        registry.updateReport(token1, score, false, false, 0, 0, 100);
        assertEq(registry.getReport(token1).score, score);
    }

    function testFuzz_isTokenSafe_threshold(uint8 score) public {
        registry.updateReport(token1, score, false, false, 0, 0, 100);
        assertEq(registry.isTokenSafe(token1), score >= 70);
    }
}

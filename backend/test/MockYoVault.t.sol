// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { MockYoVault } from "../contracts/mocks/MockYoVault.sol";
import { MockERC20 } from "../contracts/mocks/MockERC20.sol";

contract MockYoVaultTest is Test {
    MockERC20 internal eurc;
    MockYoVault internal yoVault;
    address internal user = address(0x1234);
    address internal receiver = address(0x5678);
    address internal owner = address(0x9999);

    uint256 internal constant INITIAL_EURC = 10_000 * 10 ** 6; // 10,000 EURC (6 decimals)

    function setUp() public {
        // Create EURC token with 6 decimals
        eurc = new MockERC20("EUR Coin", "EURC", 6, user, 10_000);

        // Create Yo Vault with EURC as underlying
        yoVault = new MockYoVault(address(eurc));
    }

    function test_InitialState() public view {
        assertEq(yoVault.EURC(), address(eurc), "EURC address should match");
        assertEq(yoVault.name(), "Mock Yo EUR", "name should be correct");
        assertEq(yoVault.symbol(), "yoEUR", "symbol should be correct");
        assertEq(yoVault.totalSupply(), 0, "initial total supply should be 0");
    }

    function test_DepositBasic() public {
        uint256 depositAmount = 1_000 * 10 ** 6; // 1,000 EURC

        vm.startPrank(user);
        eurc.approve(address(yoVault), depositAmount);
        uint256 shares = yoVault.deposit(depositAmount, receiver);
        vm.stopPrank();

        assertEq(shares, depositAmount, "shares should equal assets (1:1 ratio)");
        assertEq(yoVault.balanceOf(receiver), depositAmount, "receiver should have shares");
        assertEq(eurc.balanceOf(address(yoVault)), depositAmount, "vault should have EURC");
    }

    function test_DepositMultipleTimes() public {
        uint256 amount1 = 500 * 10 ** 6;
        uint256 amount2 = 300 * 10 ** 6;

        vm.startPrank(user);
        eurc.approve(address(yoVault), amount1 + amount2);
        yoVault.deposit(amount1, receiver);
        yoVault.deposit(amount2, receiver);
        vm.stopPrank();

        assertEq(
            yoVault.balanceOf(receiver),
            amount1 + amount2,
            "receiver should accumulate shares"
        );
        assertEq(
            eurc.balanceOf(address(yoVault)),
            amount1 + amount2,
            "vault should have all EURC"
        );
    }

    function test_DepositRevertZeroAmount() public {
        vm.startPrank(user);
        eurc.approve(address(yoVault), 1000 * 10 ** 6);
        vm.expectRevert("Amount must be > 0");
        yoVault.deposit(0, receiver);
        vm.stopPrank();
    }

    function test_DepositDifferentReceivers() public {
        uint256 amount1 = 500 * 10 ** 6;
        uint256 amount2 = 300 * 10 ** 6;
        address receiver2 = address(0xAAAA);

        vm.startPrank(user);
        eurc.approve(address(yoVault), amount1 + amount2);
        yoVault.deposit(amount1, receiver);
        yoVault.deposit(amount2, receiver2);
        vm.stopPrank();

        assertEq(yoVault.balanceOf(receiver), amount1, "receiver 1 should have shares");
        assertEq(yoVault.balanceOf(receiver2), amount2, "receiver 2 should have shares");
    }

    function test_RedeemBasic() public {
        uint256 depositAmount = 1_000 * 10 ** 6;

        // Deposit first
        vm.startPrank(user);
        eurc.approve(address(yoVault), depositAmount);
        yoVault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Redeem
        vm.startPrank(receiver);
        uint256 assets = yoVault.redeem(depositAmount, receiver, receiver);
        vm.stopPrank();

        assertEq(assets, depositAmount, "assets should equal shares (1:1 ratio)");
        assertEq(yoVault.balanceOf(receiver), 0, "receiver should have no shares");
        assertEq(eurc.balanceOf(receiver), depositAmount, "receiver should have EURC");
    }

    function test_RedeemPartial() public {
        uint256 depositAmount = 1_000 * 10 ** 6;
        uint256 redeemAmount = 600 * 10 ** 6;

        // Deposit
        vm.startPrank(user);
        eurc.approve(address(yoVault), depositAmount);
        yoVault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Partial redeem
        vm.startPrank(receiver);
        uint256 assets = yoVault.redeem(redeemAmount, receiver, receiver);
        vm.stopPrank();

        assertEq(assets, redeemAmount, "should redeem correct amount");
        assertEq(yoVault.balanceOf(receiver), depositAmount - redeemAmount, "shares should decrease");
        assertEq(eurc.balanceOf(receiver), redeemAmount, "receiver should get EURC");
    }

    function test_RedeemRevertZeroShares() public {
        vm.startPrank(user);
        vm.expectRevert("Shares must be > 0");
        yoVault.redeem(0, user, user);
        vm.stopPrank();
    }

    function test_RedeemDifferentReceiver() public {
        uint256 depositAmount = 1_000 * 10 ** 6;
        address redeemReceiver = address(0xBBBB);

        // Deposit to receiver
        vm.startPrank(user);
        eurc.approve(address(yoVault), depositAmount);
        yoVault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Redeem to different address
        vm.startPrank(receiver);
        yoVault.redeem(depositAmount, redeemReceiver, receiver);
        vm.stopPrank();

        assertEq(yoVault.balanceOf(receiver), 0, "original receiver should have no shares");
        assertEq(eurc.balanceOf(redeemReceiver), depositAmount, "redemption receiver should get EURC");
    }

    function test_RedeemDifferentOwner() public {
        uint256 depositAmount = 1_000 * 10 ** 6;
        address redeemer = address(0xCCCC);

        // Deposit to receiver
        vm.startPrank(user);
        eurc.approve(address(yoVault), depositAmount);
        yoVault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Transfer shares to redeemer
        vm.prank(receiver);
        yoVault.transfer(redeemer, depositAmount);

        // Redeem as owner, receive to another address
        vm.prank(redeemer);
        yoVault.redeem(depositAmount, receiver, redeemer);

        assertEq(yoVault.balanceOf(redeemer), 0, "redeemer should have no shares");
        assertEq(eurc.balanceOf(receiver), depositAmount, "receiver should get EURC");
    }

    function test_PreviewDeposit() public view {
        uint256 assets = 1_000 * 10 ** 6;
        uint256 shares = yoVault.previewDeposit(assets);
        assertEq(shares, assets, "preview should equal assets (1:1)");
    }

    function test_PreviewRedeem() public view {
        uint256 shares = 1_000 * 10 ** 6;
        uint256 assets = yoVault.previewRedeem(shares);
        assertEq(assets, shares, "preview should equal shares (1:1)");
    }

    function test_PreviewDepositVariousAmounts() public view {
        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 1 * 10 ** 6;
        amounts[1] = 100 * 10 ** 6;
        amounts[2] = 1_000 * 10 ** 6;
        amounts[3] = 10_000 * 10 ** 6;
        amounts[4] = 1_000_000 * 10 ** 6;

        for (uint256 i = 0; i < amounts.length; i++) {
            assertEq(yoVault.previewDeposit(amounts[i]), amounts[i], "1:1 ratio for all amounts");
        }
    }

    function test_DepositAndRedeemRoundtrip() public {
        uint256 initialAmount = 5_000 * 10 ** 6;

        // Deposit
        vm.startPrank(user);
        eurc.approve(address(yoVault), initialAmount);
        uint256 shares = yoVault.deposit(initialAmount, receiver);
        vm.stopPrank();

        // Redeem all
        vm.startPrank(receiver);
        uint256 assets = yoVault.redeem(shares, receiver, receiver);
        vm.stopPrank();

        assertEq(assets, initialAmount, "should recover initial amount");
        assertEq(eurc.balanceOf(receiver), initialAmount, "user should have initial EURC back");
        assertEq(yoVault.balanceOf(receiver), 0, "user should have no shares");
    }

    function test_TotalSupplyTracking() public {
        uint256 amount1 = 500 * 10 ** 6;
        uint256 amount2 = 300 * 10 ** 6;

        vm.startPrank(user);
        eurc.approve(address(yoVault), amount1 + amount2);
        yoVault.deposit(amount1, receiver);
        assertEq(yoVault.totalSupply(), amount1, "total supply should increase");

        yoVault.deposit(amount2, owner);
        assertEq(yoVault.totalSupply(), amount1 + amount2, "total supply should accumulate");
        vm.stopPrank();

        // Redeem decreases supply
        vm.prank(receiver);
        yoVault.redeem(amount1, receiver, receiver);
        assertEq(yoVault.totalSupply(), amount2, "total supply should decrease");
    }

    function test_VaultBalanceTracking() public {
        uint256 amount = 1_000 * 10 ** 6;

        vm.startPrank(user);
        eurc.approve(address(yoVault), amount);
        yoVault.deposit(amount, receiver);
        assertEq(eurc.balanceOf(address(yoVault)), amount, "vault should hold EURC");

        vm.stopPrank();

        vm.prank(receiver);
        yoVault.redeem(amount, receiver, receiver);
        assertEq(eurc.balanceOf(address(yoVault)), 0, "vault should have no EURC");
    }

    function test_DepositsFromMultipleUsers() public {
        address user2 = address(0xDEAD);
        address user3 = address(0xBEEF);
        uint256 amount = 1_000 * 10 ** 6;

        // Mint tokens to additional users
        eurc.mint(user2, amount);
        eurc.mint(user3, amount);

        // User 1 deposits
        vm.startPrank(user);
        eurc.approve(address(yoVault), amount);
        yoVault.deposit(amount, user);
        vm.stopPrank();

        // User 2 deposits
        vm.startPrank(user2);
        eurc.approve(address(yoVault), amount);
        yoVault.deposit(amount, user2);
        vm.stopPrank();

        // User 3 deposits
        vm.startPrank(user3);
        eurc.approve(address(yoVault), amount);
        yoVault.deposit(amount, user3);
        vm.stopPrank();

        assertEq(yoVault.totalSupply(), amount * 3, "total supply should accumulate");
        assertEq(eurc.balanceOf(address(yoVault)), amount * 3, "vault should hold all EURC");
    }

    function test_EURCImmutable() public view {
        assertEq(yoVault.EURC(), address(eurc), "EURC address should be immutable");
    }
}

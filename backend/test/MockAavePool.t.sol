// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import { Test } from "forge-std/Test.sol";
import { MockAavePool } from "../contracts/mocks/MockAavePool.sol";
import { MockERC20 } from "../contracts/mocks/MockERC20.sol";


contract MockAavePoolTest is Test {
    MockAavePool internal aavePool;
    MockERC20 internal usdc;
    MockERC20 internal aUsdc;
    MockERC20 internal eurc;
    MockERC20 internal aEurc;


    address internal user = address(0x1234);
    address internal onBehalfOf = address(0x5678);
    address internal receiver = address(0x9999);
    address internal owner = address(this);


    uint256 internal constant INITIAL_BALANCE = 10_000; // tokens (will be multiplied by 10**decimals in constructor)
    uint256 internal constant INITIAL_BALANCE_UNITS = 10_000 * 10 ** 6; // base units (10^6 decimals)


    function setUp() public {
        // Deploy Aave pool
        aavePool = new MockAavePool();


        // Create USDC and aUSDC
        usdc = new MockERC20("USD Coin", "USDC", 6, user, INITIAL_BALANCE);
        aUsdc = new MockERC20("aUSDC", "aUSDC", 6, address(aavePool), 0);


        // Create EURC and aEURC
        eurc = new MockERC20("EUR Coin", "EURC", 6, user, INITIAL_BALANCE);
        aEurc = new MockERC20("aEURC", "aEURC", 6, address(aavePool), 0);


        // Set underlying assets in pool
        aavePool.setUnderlying(address(usdc), address(aUsdc));
        aavePool.setUnderlying(address(eurc), address(aEurc));
    }


    function test_InitialState() public view {
        assertEq(aavePool.owner(), owner, "owner should be set");
        assertEq(aavePool.aTokens(address(usdc)), address(aUsdc), "aToken mapping for USDC");
        assertEq(aavePool.aTokens(address(eurc)), address(aEurc), "aToken mapping for EURC");
    }


    function test_SetUnderlyingOnlyOwner() public {
        address newAToken = address(0xAAAA);


        // Owner can set
        aavePool.setUnderlying(address(usdc), newAToken);
        assertEq(aavePool.aTokens(address(usdc)), newAToken, "owner should be able to set");


        // Non-owner cannot set
        vm.prank(user);
        vm.expectRevert(MockAavePool.NotOwner.selector);
        aavePool.setUnderlying(address(eurc), newAToken);
    }


    function test_SupplyBasic() public {
        uint256 supplyAmount = 1_000 * 10 ** 6; // 1,000 USDC in base units


        vm.startPrank(user);
        usdc.approve(address(aavePool), supplyAmount);
        aavePool.supply(address(usdc), supplyAmount, onBehalfOf, 0);
        vm.stopPrank();


        assertEq(
            aUsdc.balanceOf(onBehalfOf),
            supplyAmount,
            "onBehalfOf should receive aTokens"
        );
        assertEq(
            usdc.balanceOf(address(aavePool)),
            supplyAmount,
            "pool should hold underlying"
        );
        assertEq(
            usdc.balanceOf(user),
            INITIAL_BALANCE_UNITS - supplyAmount,
            "user balance should decrease"
        );
    }


    function test_SupplyMultipleTimes() public {
        uint256 amount1 = 500 * 10 ** 6;
        uint256 amount2 = 300 * 10 ** 6;


        vm.startPrank(user);
        usdc.approve(address(aavePool), amount1 + amount2);
        aavePool.supply(address(usdc), amount1, onBehalfOf, 0);
        aavePool.supply(address(usdc), amount2, onBehalfOf, 0);
        vm.stopPrank();


        assertEq(
            aUsdc.balanceOf(onBehalfOf),
            amount1 + amount2,
            "aToken balance should accumulate"
        );
        assertEq(
            usdc.balanceOf(address(aavePool)),
            amount1 + amount2,
            "pool should accumulate underlying"
        );
    }


    function test_SupplyDifferentReceivers() public {
        uint256 amount1 = 500 * 10 ** 6;
        uint256 amount2 = 300 * 10 ** 6;
        address onBehalfOf2 = address(0xBBBB);


        vm.startPrank(user);
        usdc.approve(address(aavePool), amount1 + amount2);
        aavePool.supply(address(usdc), amount1, onBehalfOf, 0);
        aavePool.supply(address(usdc), amount2, onBehalfOf2, 0);
        vm.stopPrank();


        assertEq(aUsdc.balanceOf(onBehalfOf), amount1, "first receiver should have aTokens");
        assertEq(aUsdc.balanceOf(onBehalfOf2), amount2, "second receiver should have aTokens");
    }


    function test_SupplyRevertZeroAmount() public {
        vm.startPrank(user);
        usdc.approve(address(aavePool), 1000 * 10 ** 6);
        vm.expectRevert("Amount must be > 0");
        aavePool.supply(address(usdc), 0, onBehalfOf, 0);
        vm.stopPrank();
    }


    function test_SupplyRevertUnsupportedAsset() public {
        address unsupportedAsset = address(0xDEAD);
        uint256 amount = 1_000 * 10 ** 6;


        vm.startPrank(user);
        vm.expectRevert("Asset not supported");
        aavePool.supply(unsupportedAsset, amount, onBehalfOf, 0);
        vm.stopPrank();
    }


    function test_SupplyMultipleAssets() public {
        uint256 usdcAmount = 1_000 * 10 ** 6;
        uint256 eurcAmount = 500 * 10 ** 6;


        vm.startPrank(user);
        usdc.approve(address(aavePool), usdcAmount);
        eurc.approve(address(aavePool), eurcAmount);


        aavePool.supply(address(usdc), usdcAmount, onBehalfOf, 0);
        aavePool.supply(address(eurc), eurcAmount, onBehalfOf, 0);
        vm.stopPrank();


        assertEq(
            aUsdc.balanceOf(onBehalfOf),
            usdcAmount,
            "should have aUSDC"
        );
        assertEq(
            aEurc.balanceOf(onBehalfOf),
            eurcAmount,
            "should have aEURC"
        );
    }


    function test_WithdrawBasic() public {
        uint256 supplyAmount = 1_000 * 10 ** 6;


        // First supply
        vm.startPrank(user);
        usdc.approve(address(aavePool), supplyAmount);
        aavePool.supply(address(usdc), supplyAmount, onBehalfOf, 0);
        vm.stopPrank();


        // Then withdraw
        vm.startPrank(onBehalfOf);
        uint256 withdrawnAmount = aavePool.withdraw(address(usdc), supplyAmount, receiver);
        vm.stopPrank();


        assertEq(withdrawnAmount, supplyAmount, "should return withdrawn amount");
        assertEq(
            aUsdc.balanceOf(onBehalfOf),
            0,
            "aToken balance should be zero after full withdraw"
        );
        assertEq(
            usdc.balanceOf(receiver),
            supplyAmount,
            "receiver should get underlying"
        );
        assertEq(
            usdc.balanceOf(address(aavePool)),
            0,
            "pool should have no underlying left"
        );
    }


    function test_WithdrawPartial() public {
        uint256 supplyAmount = 1_000 * 10 ** 6;
        uint256 withdrawAmount = 600 * 10 ** 6;


        // Supply
        vm.startPrank(user);
        usdc.approve(address(aavePool), supplyAmount);
        aavePool.supply(address(usdc), supplyAmount, onBehalfOf, 0);
        vm.stopPrank();


        // Partial withdraw
        vm.startPrank(onBehalfOf);
        aavePool.withdraw(address(usdc), withdrawAmount, receiver);
        vm.stopPrank();


        assertEq(
            aUsdc.balanceOf(onBehalfOf),
            supplyAmount - withdrawAmount,
            "aToken balance should decrease"
        );
        assertEq(
            usdc.balanceOf(receiver),
            withdrawAmount,
            "receiver should get partial amount"
        );
        assertEq(
            usdc.balanceOf(address(aavePool)),
            supplyAmount - withdrawAmount,
            "pool should have remaining"
        );
    }


    function test_WithdrawRevertZeroAmount() public {
        vm.startPrank(user);
        vm.expectRevert("Amount must be > 0");
        aavePool.withdraw(address(usdc), 0, receiver);
        vm.stopPrank();
    }


    function test_WithdrawRevertUnsupportedAsset() public {
        address unsupportedAsset = address(0xDEAD);


        vm.startPrank(user);
        vm.expectRevert("Asset not supported");
        aavePool.withdraw(unsupportedAsset, 1000 * 10 ** 6, receiver);
        vm.stopPrank();
    }


    function test_WithdrawDifferentReceiver() public {
        uint256 supplyAmount = 1_000 * 10 ** 6;
        address withdrawReceiver = address(0xCCCC);


        // Supply to onBehalfOf
        vm.startPrank(user);
        usdc.approve(address(aavePool), supplyAmount);
        aavePool.supply(address(usdc), supplyAmount, onBehalfOf, 0);
        vm.stopPrank();


        // Withdraw to different address
        vm.startPrank(onBehalfOf);
        aavePool.withdraw(address(usdc), supplyAmount, withdrawReceiver);
        vm.stopPrank();


        assertEq(
            usdc.balanceOf(withdrawReceiver),
            supplyAmount,
            "different receiver should get assets"
        );
        assertEq(usdc.balanceOf(receiver), 0, "original receiver should have nothing");
    }


    function test_SupplyAndWithdrawRoundtrip() public {
        uint256 amount = 5_000 * 10 ** 6;


        // Supply
        vm.startPrank(user);
        usdc.approve(address(aavePool), amount);
        aavePool.supply(address(usdc), amount, onBehalfOf, 0);
        vm.stopPrank();


        uint256 aTokenBalance = aUsdc.balanceOf(onBehalfOf);
        assertEq(aTokenBalance, amount, "should have aTokens equal to supply");


        // Withdraw all
        vm.startPrank(onBehalfOf);
        uint256 withdrawn = aavePool.withdraw(address(usdc), aTokenBalance, receiver);
        vm.stopPrank();


        assertEq(withdrawn, amount, "should withdraw initial amount");
        assertEq(usdc.balanceOf(receiver), amount, "receiver should get all");
        assertEq(aUsdc.balanceOf(onBehalfOf), 0, "no aTokens left");
    }


    function test_MultipleSupplyAndWithdraw() public {
        uint256 amount1 = 500 * 10 ** 6;
        uint256 amount2 = 300 * 10 ** 6;
        uint256 amount3 = 200 * 10 ** 6;


        // Supply 1
        vm.startPrank(user);
        usdc.approve(address(aavePool), amount1 + amount2 + amount3);
        aavePool.supply(address(usdc), amount1, onBehalfOf, 0);
        vm.stopPrank();


        assertEq(aUsdc.balanceOf(onBehalfOf), amount1, "first supply");


        // Supply 2
        vm.startPrank(user);
        aavePool.supply(address(usdc), amount2, onBehalfOf, 0);
        vm.stopPrank();


        assertEq(aUsdc.balanceOf(onBehalfOf), amount1 + amount2, "accumulated supplies");


        // Withdraw partial
        vm.startPrank(onBehalfOf);
        aavePool.withdraw(address(usdc), amount1, receiver);
        vm.stopPrank();


        assertEq(aUsdc.balanceOf(onBehalfOf), amount2, "after first withdraw");
        assertEq(usdc.balanceOf(receiver), amount1, "receiver gets first amount");


        // Supply 3
        vm.startPrank(user);
        aavePool.supply(address(usdc), amount3, onBehalfOf, 0);
        vm.stopPrank();


        assertEq(aUsdc.balanceOf(onBehalfOf), amount2 + amount3, "second supply added");


        // Withdraw all
        vm.startPrank(onBehalfOf);
        aavePool.withdraw(address(usdc), amount2 + amount3, receiver);
        vm.stopPrank();


        assertEq(aUsdc.balanceOf(onBehalfOf), 0, "all withdrawn");
        assertEq(usdc.balanceOf(receiver), amount1 + amount2 + amount3, "receiver has all");
    }


    function test_SupplyAndWithdrawMultipleAssets() public {
        uint256 usdcSupply = 1_000 * 10 ** 6;
        uint256 eurcSupply = 500 * 10 ** 6;


        // Supply both
        vm.startPrank(user);
        usdc.approve(address(aavePool), usdcSupply);
        eurc.approve(address(aavePool), eurcSupply);
        aavePool.supply(address(usdc), usdcSupply, onBehalfOf, 0);
        aavePool.supply(address(eurc), eurcSupply, onBehalfOf, 0);
        vm.stopPrank();


        // Withdraw USDC
        vm.startPrank(onBehalfOf);
        aavePool.withdraw(address(usdc), usdcSupply, receiver);
        vm.stopPrank();


        assertEq(aUsdc.balanceOf(onBehalfOf), 0, "aUSDC withdrawn");
        assertEq(aEurc.balanceOf(onBehalfOf), eurcSupply, "aEURC still there");
        assertEq(usdc.balanceOf(receiver), usdcSupply, "USDC received");


        // Withdraw EURC
        vm.startPrank(onBehalfOf);
        aavePool.withdraw(address(eurc), eurcSupply, receiver);
        vm.stopPrank();


        assertEq(aEurc.balanceOf(onBehalfOf), 0, "all withdrawn");
        assertEq(usdc.balanceOf(receiver), usdcSupply, "USDC still there");
        assertEq(eurc.balanceOf(receiver), eurcSupply, "EURC received");
    }


    function test_PoolBalanceTracking() public {
        uint256 amount1 = 1_000 * 10 ** 6;
        uint256 amount2 = 500 * 10 ** 6;


        vm.startPrank(user);
        usdc.approve(address(aavePool), amount1 + amount2);
        aavePool.supply(address(usdc), amount1, onBehalfOf, 0);
        assertEq(usdc.balanceOf(address(aavePool)), amount1, "pool balance after first supply");


        aavePool.supply(address(usdc), amount2, onBehalfOf, 0);
        assertEq(
            usdc.balanceOf(address(aavePool)),
            amount1 + amount2,
            "pool balance accumulates"
        );
        vm.stopPrank();


        vm.prank(onBehalfOf);
        aavePool.withdraw(address(usdc), amount1, receiver);
        assertEq(usdc.balanceOf(address(aavePool)), amount2, "pool balance decreases");
    }


    function test_ReferralCodeIgnored() public {
        uint256 amount = 1_000 * 10 ** 6;
        uint16 referralCode = 12345;


        vm.startPrank(user);
        usdc.approve(address(aavePool), amount);
        aavePool.supply(address(usdc), amount, onBehalfOf, referralCode);
        vm.stopPrank();


        // Should work the same regardless of referral code
        assertEq(aUsdc.balanceOf(onBehalfOf), amount, "supply works with referral code");
    }


    function test_SupplyWithDifferentDecimals() public {
        // Create token with different decimals (pass 5_000 tokens, not 5_000 * 10**6)
        MockERC20 usdt = new MockERC20("Tether", "USDT", 6, user, 5_000);
        MockERC20 aUsdt = new MockERC20("aUSDT", "aUSDT", 6, address(aavePool), 0);


        aavePool.setUnderlying(address(usdt), address(aUsdt));


        uint256 amount = 2_000 * 10 ** 6;


        vm.startPrank(user);
        usdt.approve(address(aavePool), amount);
        aavePool.supply(address(usdt), amount, onBehalfOf, 0);
        vm.stopPrank();


        assertEq(aUsdt.balanceOf(onBehalfOf), amount, "6-decimal token supply");
    }


    function test_ATokenMappingUpdates() public {
        address newAToken = address(0xAAAA);


        aavePool.setUnderlying(address(usdc), newAToken);
        assertEq(aavePool.aTokens(address(usdc)), newAToken, "mapping should update");


        address newerAToken = address(0xBBBB);
        aavePool.setUnderlying(address(usdc), newerAToken);
        assertEq(aavePool.aTokens(address(usdc)), newerAToken, "mapping should update again");
    }


    function test_OwnerImmutable() public view {
        assertEq(aavePool.owner(), owner, "owner should be set to deployer");
    }
}

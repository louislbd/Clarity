// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "../contracts/mocks/MockERC20.sol";

contract MockERC20Test is Test {
    MockERC20 internal token;
    address internal user = address(0x1234);
    address internal recipient = address(0x5678);

    function setUp() public {
        // Create token with 18 decimals
        token = new MockERC20("Test Token", "TST", 18, user, 1000);
    }

    function test_InitialDecimals() public view {
        assertEq(token.decimals(), 18, "decimals should be 18");
    }

    function test_InitialSupply() public view {
        assertEq(token.balanceOf(user), 1000 * 10 ** 18, "initial supply should be 1000 tokens");
    }

    function test_Name() public view {
        assertEq(token.name(), "Test Token", "name should match");
    }

    function test_Symbol() public view {
        assertEq(token.symbol(), "TST", "symbol should match");
    }

    function test_Mint() public {
        uint256 mintAmount = 100 * 10 ** 18;
        token.mint(recipient, mintAmount);
        assertEq(token.balanceOf(recipient), mintAmount, "recipient should have minted tokens");
    }

    function test_MintMultipleTimes() public {
        token.mint(recipient, 100 * 10 ** 18);
        token.mint(recipient, 50 * 10 ** 18);
        assertEq(token.balanceOf(recipient), 150 * 10 ** 18, "balance should accumulate");
    }

    function test_Burn() public {
        uint256 burnAmount = 100 * 10 ** 18;
        token.burn(user, burnAmount);
        assertEq(
            token.balanceOf(user),
            (1000 * 10 ** 18) - burnAmount,
            "balance should decrease after burn"
        );
    }

    function test_BurnMultipleTimes() public {
        token.burn(user, 100 * 10 ** 18);
        token.burn(user, 50 * 10 ** 18);
        assertEq(
            token.balanceOf(user),
            (1000 * 10 ** 18) - 150 * 10 ** 18,
            "balance should decrease with multiple burns"
        );
    }

    function test_MintAndBurn() public {
        token.mint(recipient, 500 * 10 ** 18);
        assertEq(token.balanceOf(recipient), 500 * 10 ** 18, "mint successful");

        token.burn(recipient, 200 * 10 ** 18);
        assertEq(token.balanceOf(recipient), 300 * 10 ** 18, "burn reduces balance");
    }

    function test_Different_Decimals_6() public {
        MockERC20 token6 = new MockERC20("USDC", "USDC", 6, user, 1000);
        assertEq(token6.decimals(), 6, "decimals should be 6");
        assertEq(token6.balanceOf(user), 1000 * 10 ** 6, "initial supply with 6 decimals");
    }

    function test_Different_Decimals_8() public {
        MockERC20 token8 = new MockERC20("BTC", "BTC", 8, user, 100);
        assertEq(token8.decimals(), 8, "decimals should be 8");
        assertEq(token8.balanceOf(user), 100 * 10 ** 8, "initial supply with 8 decimals");
    }

    function test_TotalSupplyIncreases() public {
        uint256 initialSupply = token.totalSupply();
        token.mint(recipient, 500 * 10 ** 18);
        assertEq(
            token.totalSupply(),
            initialSupply + 500 * 10 ** 18,
            "total supply should increase"
        );
    }

    function test_TotalSupplyDecreases() public {
        uint256 initialSupply = token.totalSupply();
        token.burn(user, 100 * 10 ** 18);
        assertEq(
            token.totalSupply(),
            initialSupply - 100 * 10 ** 18,
            "total supply should decrease"
        );
    }

    function test_Transfer() public {
        vm.prank(user);
        token.transfer(recipient, 100 * 10 ** 18);
        assertEq(token.balanceOf(recipient), 100 * 10 ** 18, "recipient should receive tokens");
        assertEq(
            token.balanceOf(user),
            (1000 * 10 ** 18) - 100 * 10 ** 18,
            "sender balance should decrease"
        );
    }

    function test_Approve() public {
        vm.prank(user);
        token.approve(recipient, 500 * 10 ** 18);
        assertEq(token.allowance(user, recipient), 500 * 10 ** 18, "allowance should be set");
    }

    function test_TransferFrom() public {
        vm.prank(user);
        token.approve(recipient, 500 * 10 ** 18);

        vm.prank(recipient);
        token.transferFrom(user, recipient, 300 * 10 ** 18);

        assertEq(token.balanceOf(recipient), 300 * 10 ** 18, "recipient should have tokens");
        assertEq(
            token.allowance(user, recipient),
            200 * 10 ** 18,
            "allowance should decrease"
        );
    }
}

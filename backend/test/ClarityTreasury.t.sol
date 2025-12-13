// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import { ClarityTreasury } from "../contracts/ClarityTreasury.sol";
import { ClarityUtils } from "../contracts/ClarityUtils.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Simple test ERC20 with 6 decimals for USDC-like behavior
contract TestERC20 is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_)
        ERC20(name_, symbol_)
    {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract ClarityTreasuryTest is Test {
    ClarityTreasury treasury;
    ERC20 mockToken;
    address teamWallet = makeAddr("teamWallet");
    address owner = makeAddr("owner");
    address vault1 = makeAddr("vault1");
    address vault2 = makeAddr("vault2");
    address recipient = makeAddr("recipient");

    function setUp() public {
        // Deploy mock token
        mockToken = ERC20(address(new TestERC20("Mock Token", "MTK", 18)));

        // Deploy treasury
        vm.prank(owner);
        treasury = new ClarityTreasury(teamWallet);

        // Mint tokens to vaults and approve treasury
        deal(address(mockToken), vault1, 1000 ether);
        deal(address(mockToken), vault2, 1000 ether);
        vm.prank(vault1);
        mockToken.approve(address(treasury), type(uint256).max);
        vm.prank(vault2);
        mockToken.approve(address(treasury), type(uint256).max);
    }

    function test_InitialState() public {
        assertEq(treasury.owner(), owner);
        assertEq(treasury.teamWallet(), teamWallet);
        assertEq(treasury.emergencyLPBP(), 2000); // 20%
        assertEq(treasury.vaultFeesReceived(vault1), 0);
    }

    function test_ReceiveFees() public {
        uint256 amount = 100 ether;

        vm.prank(vault1);
        treasury.receiveFees(address(mockToken), amount);

        assertEq(mockToken.balanceOf(address(treasury)), amount);
        assertEq(treasury.vaultFeesReceived(vault1), amount);
    }

    function test_ReceiveFees_RevertZeroAmount() public {
        vm.expectRevert(ClarityTreasury.FeeAmountZero.selector);
        vm.prank(vault1);
        treasury.receiveFees(address(mockToken), 0);
    }

    function test_DistributeFees() public {
        uint256 depositAmount = 1000 ether;
        vm.prank(vault1);
        treasury.receiveFees(address(mockToken), depositAmount);

        uint256 teamBalanceBefore = mockToken.balanceOf(teamWallet);

        vm.prank(owner);
        treasury.distributeFees(address(mockToken));

        uint256 expectedLP = (depositAmount * 2000) / ClarityUtils.BASIS_POINTS; // 20%
        uint256 expectedTeam = depositAmount - expectedLP;                       // 80%

        assertEq(
            mockToken.balanceOf(teamWallet),
            teamBalanceBefore + expectedTeam
        );
        assertEq(
            mockToken.balanceOf(address(treasury)),
            expectedLP
        );
    }


    function test_DistributeFees_RevertEmptyBalance() public {
        vm.expectRevert(ClarityTreasury.EmptyBalance.selector);
        vm.prank(owner);
        treasury.distributeFees(address(mockToken));
    }

    function test_EmergencyWithdraw() public {
        uint256 depositAmount = 1000 ether;
        vm.prank(vault1);
        treasury.receiveFees(address(mockToken), depositAmount);

        uint256 recipientBalanceBefore = mockToken.balanceOf(recipient);
        vm.prank(owner);
        treasury.emergencyWithdraw(address(mockToken), recipient, 500 ether);

        assertEq(mockToken.balanceOf(recipient), recipientBalanceBefore + 500 ether);
        assertEq(mockToken.balanceOf(address(treasury)), depositAmount - 500 ether);
    }

    function test_EmergencyWithdraw_RevertZeroAmount() public {
        vm.expectRevert(ClarityTreasury.AmountZero.selector);
        vm.prank(owner);
        treasury.emergencyWithdraw(address(mockToken), recipient, 0);
    }

    function test_EmergencyWithdraw_RevertNotOwner() public {
        uint256 depositAmount = 100 ether;
        vm.prank(vault1);
        treasury.receiveFees(address(mockToken), depositAmount);

        vm.expectRevert();
        vm.prank(recipient);
        treasury.emergencyWithdraw(address(mockToken), recipient, 50 ether);
    }

    function test_SetTeamWallet() public {
        address newWallet = makeAddr("newTeamWallet");

        vm.prank(owner);
        treasury.setTeamWallet(newWallet);

        assertEq(treasury.teamWallet(), newWallet);
    }

    function test_SetTeamWallet_RevertZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(ClarityTreasury.AddressZero.selector);
        treasury.setTeamWallet(address(0));
    }

    function test_SetTeamWallet_RevertNotOwner() public {
        address newWallet = makeAddr("newTeamWallet");
        vm.expectRevert();
        vm.prank(recipient);
        treasury.setTeamWallet(newWallet);
    }

    function test_SetEmergencyLPBP() public {
        vm.prank(owner);
        treasury.setEmergencyLPBP(3000); // 30%

        assertEq(treasury.emergencyLPBP(), 3000);
    }

    function test_SetEmergencyLPBP_RevertTooHigh() public {
        vm.prank(owner);
        vm.expectRevert(ClarityTreasury.TooHigh.selector);
        treasury.setEmergencyLPBP(ClarityUtils.BASIS_POINTS + 1);
    }

    function test_SetEmergencyLPBP_ZeroAllowed() public {
        vm.prank(owner);
        treasury.setEmergencyLPBP(0);
        assertEq(treasury.emergencyLPBP(), 0);
    }

    function test_SetEmergencyLPBP_RevertNotOwner() public {
        vm.expectRevert();
        vm.prank(recipient);
        treasury.setEmergencyLPBP(1500);
    }

    function test_MultipleVaults() public {
        uint256 vault1Amount = 500 ether;
        uint256 vault2Amount = 300 ether;

        vm.prank(vault1);
        treasury.receiveFees(address(mockToken), vault1Amount);
        vm.prank(vault2);
        treasury.receiveFees(address(mockToken), vault2Amount);

        assertEq(treasury.vaultFeesReceived(vault1), vault1Amount);
        assertEq(treasury.vaultFeesReceived(vault2), vault2Amount);
        assertEq(mockToken.balanceOf(address(treasury)), vault1Amount + vault2Amount);
    }

    function test_DistributeFees_AfterMultipleDeposits() public {
        uint256 totalDeposit = 1500 ether;
        vm.prank(vault1);
        treasury.receiveFees(address(mockToken), 1000 ether);
        vm.prank(vault2);
        treasury.receiveFees(address(mockToken), 500 ether);

        uint256 teamBalanceBefore = mockToken.balanceOf(teamWallet);

        vm.prank(owner);
        treasury.distributeFees(address(mockToken));

        uint256 expectedLP = (totalDeposit * 2000) / ClarityUtils.BASIS_POINTS; // 20%
        uint256 expectedTeam = totalDeposit - expectedLP;                       // 80%

        assertEq(
            mockToken.balanceOf(teamWallet),
            teamBalanceBefore + expectedTeam
        );
        assertEq(
            mockToken.balanceOf(address(treasury)),
            expectedLP
        );
    }


    function test_EmergencyWithdraw_EntireBalance() public {
        uint256 depositAmount = 100 ether;
        vm.prank(vault1);
        treasury.receiveFees(address(mockToken), depositAmount);

        vm.prank(owner);
        treasury.emergencyWithdraw(address(mockToken), recipient, depositAmount);

        assertEq(mockToken.balanceOf(address(treasury)), 0);
        assertEq(mockToken.balanceOf(recipient), depositAmount);
    }

    function test_ReceiveFees_MultipleTokens() public {
        ERC20 mockToken2 = new TestERC20("Mock Token 2", "MTK2", 18);
        deal(address(mockToken2), vault1, 200 ether);
        vm.prank(vault1);
        mockToken2.approve(address(treasury), type(uint256).max);

        vm.prank(vault1);
        treasury.receiveFees(address(mockToken2), 100 ether);

        assertEq(mockToken2.balanceOf(address(treasury)), 100 ether);
    }
}

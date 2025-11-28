// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ClarityUtils } from "./ClarityUtils.sol";

contract ClarityTreasury is Ownable {
    using SafeERC20 for IERC20;

    // Emergency liquidity pool ratio (basis points, e.g., 2000 = 20%)
    uint256 public emergencyLPBP = 2000;

    // Core team funding address
    address public teamWallet;

    // Mapping: vault => accumulated fees received
    mapping(address => uint256) public vaultFeesReceived;

    /// Emitted when fees are received from a vault
    event FeesReceived(address indexed vault, address indexed asset, uint256 amount);

    /// Emitted when an emergency withdrawal is made
    event EmergencyWithdrawal(address indexed vault, address indexed asset, uint256 amount);

    /// Emitted when fees are distributed
    event FeesDistributed(address indexed asset, uint256 toEmergencyLPBP, uint256 toTeam);

    /// Emitted when the team wallet is updated
    event UpdatedTeamWallet(address indexed newWallet);

    /// Emitted when the emergency liquidity pool basis points are updated
    event UpdatedEmergencyLPBP(uint256 newLP);

    error AddressZero();
    error FeeAmountZero();
    error AmountZero();
    error EmptyBalance();
    error TooHigh();

    constructor(address _teamWallet) Ownable(msg.sender) {
        require(_teamWallet != address(0), AddressZero());

        teamWallet = _teamWallet;
    }

    /**
     * @notice Receive fees from a vault.
     * @param asset The address of the asset being transferred as fees.
     * @param amount The amount of fees being transferred.
     */
    function receiveFees(address asset, uint256 amount) external {
        require(amount > 0, FeeAmountZero());

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        vaultFeesReceived[msg.sender] += amount;

        emit FeesReceived(msg.sender, asset, amount);
    }

    /**
     * @notice Distribute accumulated fees to the emergency liquidity pool and the team wallet.
     * @param asset The address of the asset to distribute.
     */
    function distributeFees(address asset) external {
        uint256 totalBalance = IERC20(asset).balanceOf(address(this));
        require(totalBalance > 0, EmptyBalance());
        uint256 toEmergencyLPBP = (totalBalance * emergencyLPBP) / ClarityUtils.BASIS_POINTS;
        // 40% example
        // TODO: Define real revenues allocation
        uint256 toTeam = (totalBalance * (ClarityUtils.BASIS_POINTS - emergencyLPBP)) / (2 * ClarityUtils.BASIS_POINTS);

        if (toEmergencyLPBP > 0) IERC20(asset).safeTransfer(teamWallet, toEmergencyLPBP);
        if (toTeam > 0) IERC20(asset).safeTransfer(teamWallet, toTeam);
        // TODO: Buyback and burn Clarity tokens with team funds?

        emit FeesDistributed(asset, toEmergencyLPBP, toTeam);
    }

    /**
     * @notice Emergency withdrawal of assets from the treasury.
     * @param asset The address of the asset to withdraw.
     * @param to The address to receive the withdrawn assets.
     * @param amount The amount of assets to withdraw.
     */
    function emergencyWithdraw(address asset, address to, uint256 amount) external onlyOwner {
        require(amount > 0, AmountZero());

        IERC20(asset).safeTransfer(to, amount);

        emit EmergencyWithdrawal(to, asset, amount);
    }

    /**
     * @notice Set a new team wallet address.
     * @dev Only callable by the owner.
     * @param newWallet The new team wallet address.
     */
    function setTeamWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), AddressZero());

        teamWallet = newWallet;

        emit UpdatedTeamWallet(newWallet);
    }

    /**
     * @notice Set a new emergency liquidity pool basis points.
     * @dev Only callable by the owner.
     * @param newBP The new emergency liquidity pool basis points.
     */
    function setEmergencyLPBP(uint256 newBP) external onlyOwner {
        require(newBP <= ClarityUtils.BASIS_POINTS, TooHigh());

        emergencyLPBP = newBP;

        emit UpdatedEmergencyLPBP(newBP);
    }
}

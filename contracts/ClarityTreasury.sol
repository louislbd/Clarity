// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ClarityUtils } from "./ClarityUtils.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract ClarityTreasury is Ownable {
    using SafeERC20 for IERC20;

    // Core team & development funding addresses
    address public teamWallet;
    address public devWallet;

    // Mapping: vault => accumulated fees received
    mapping(address => uint256) public vaultFeesReceived;

    event FeesReceived(address indexed vault, address indexed asset, uint256 amount);
    event EmergencyWithdrawal(address indexed vault, address indexed asset, uint256 amount);
    event FeesDistributed(address indexed asset, uint256 toEmergencyLPBP, uint256 toTeam, uint256 toDev);
    event UpdatedTeamWallet(address indexed newWallet);
    event UpdatedDevWallet(address indexed newWallet);
    event UpdatedEmergencyLPBP(uint256 newLP);

    error AddressZero();
    error FeeAmountZero();
    error AmountZero();
    error EmptyBalance();

    constructor(address _teamWallet, address _devWallet) {
        require(_teamWallet != address(0), AddressZero());
        require(_devWallet != address(0), AddressZero());

        teamWallet = _teamWallet;
        devWallet = _devWallet;
    }

    // Called by vaults to send fee revenue to the treasury
    function receiveFees(address asset, uint256 amount) external {
        require(amount > 0, FeeAmountZero());

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        vaultFeesReceived[msg.sender] += amount;

        emit FeesReceived(msg.sender, asset, amount);
    }

    // Distribute fees. Anyone can call to trigger distribution if assets are present.
    function distributeFees(address asset) external {
        uint256 totalBalance = IERC20(asset).balanceOf(address(this));
        require(totalBalance > 0, EmptyBalance());
        uint256 toEmergencyLPBP = (totalBalance * ClarityUtils.emergencyLPBP) / ClarityUtils.BASIS_POINTS;
        // 40% example
        uint256 toTeam = (totalBalance * (ClarityUtils.BASIS_POINTS - ClarityUtils.emergencyLPBP)) / (2 * ClarityUtils.BASIS_POINTS);
        uint256 toDev = totalBalance - toEmergencyLPBP - toTeam;

        if (toEmergencyLPBP > 0) IERC20(asset).safeTransfer(address(this), toEmergencyLPBP); // Kept as pool
        if (toTeam > 0) IERC20(asset).safeTransfer(teamWallet, toTeam);
        if (toDev > 0) IERC20(asset).safeTransfer(devWallet, toDev);

        emit FeesDistributed(asset, toEmergencyLPBP, toTeam, toDev);
    }

    // Emergency: allow manager/vaults to pull funds from emergency pool
    function emergencyWithdraw(address asset, address to, uint256 amount) external onlyOwner {
        require(amount > 0, AmountZero());

        IERC20(asset).safeTransfer(to, amount);

        emit EmergencyWithdrawal(to, asset, amount);
    }

    // Admin setters
    function setTeamWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), AddressZero());

        teamWallet = newWallet;

        emit UpdatedTeamWallet(newWallet);
    }

    function setDevWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), AddressZero());

        devWallet = newWallet;

        emit UpdatedDevWallet(newWallet);
    }

    function setEmergencyLPBPBP(uint256 newBP) external onlyOwner {
        require(newBP <= ClarityUtils.BASIS_POINTS, "Too high");

        ClarityUtils.emergencyLPBP = newBP;

        emit UpdatedEmergencyLPBPBP(newBP);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice Minimal mock of Yo Protocol EUR vault for testnet.
 * Deposits EURC, receive yoEUR (1:1 ratio, no yield here).
 */
contract MockYoVault is ERC20 {
    using SafeERC20 for IERC20;

    address public immutable EURC;

    constructor(address _eurc) ERC20("Mock Yo EUR", "yoEUR") {
        EURC = _eurc;
    }

    /**
     * @notice Deposit EURC and get yoEUR.
     */
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares) {
        require(assets > 0, "Amount must be > 0");

        // 1:1 ratio (no yield)
        shares = assets;

        // Transfer EURC from caller to vault
        IERC20(EURC).safeTransferFrom(msg.sender, address(this), assets);

        // Mint yoEUR to receiver
        _mint(receiver, shares);

        return shares;
    }

    /**
     * @notice Redeem yoEUR and get back EURC.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets) {
        require(shares > 0, "Shares must be > 0");

        // 1:1 ratio
        assets = shares;

        // Burn yoEUR from owner
        _burn(owner, shares);

        // Transfer EURC to receiver
        IERC20(EURC).safeTransfer(receiver, assets);

        return assets;
    }

    function previewDeposit(uint256 assets) external pure returns (uint256) {
        return assets;
    }

    function previewRedeem(uint256 shares) external pure returns (uint256) {
        return shares;
    }
}

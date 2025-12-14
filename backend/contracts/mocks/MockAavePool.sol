// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { MockERC20 } from "./MockERC20.sol";

/**
 * @notice Minimal mock of Aave EUR vault for testnet.
 * Deposits EURC, receive aEUR (1:1 ratio, no yield here).
 */
contract MockAavePool {
    using SafeERC20 for IERC20;

    // underlying => aToken
    mapping(address => address) public aTokens;
    address public owner;

    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    function setUnderlying(address underlying, address aToken) external {
        if (msg.sender != owner) revert NotOwner();
        aTokens[underlying] = aToken;
    }

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 /* referralCode */
    ) external {
        address aToken = aTokens[asset];
        require(aToken != address(0), "Asset not supported");
        require(amount > 0, "Amount must be > 0");

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        MockERC20(aToken).mint(onBehalfOf, amount);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        address aToken = aTokens[asset];
        require(aToken != address(0), "Asset not supported");
        require(amount > 0, "Amount must be > 0");

        // Burn aTokens from owner
        MockERC20(aToken).burn(msg.sender, amount);

        // Transfer underlying to receiver
        IERC20(asset).safeTransfer(to, amount);

        return amount;
    }

}

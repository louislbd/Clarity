// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IAavePool } from "../interfaces/IAavePool.sol";

/// @dev Minimal mock Aave pool to track supply/withdraw calls
contract MockAavePool is IAavePool {
    event Supplied(address asset, uint256 amount, address onBehalfOf, uint16 referralCode);
    event Withdrawn(address asset, uint256 amount, address to);

    // simple accounting: asset => balance
    mapping(address => uint256) public balances;

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external override {
        balances[asset] += amount;
        emit Supplied(asset, amount, onBehalfOf, referralCode);
    }

    function withdraw(address asset, uint256 amount, address to) external override returns (uint256) {
        require(balances[asset] >= amount, "insufficient mock balance");
        balances[asset] -= amount;
        emit Withdrawn(asset, amount, to);
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/** @title IAavePool
 *  @author louislbd
 *  @notice This interface defines the functions for interacting with the Aave Pool.
 *  @custom:school This interface was developed as part of a school project.
 */
interface IAavePool {
    /** @notice Supplies a specific amount of an asset into the Aave Pool.
     * @param asset The address of the asset to supply.
     * @param amount The amount of the asset to supply.
     * @param onBehalfOf The address that will receive the aTokens.
     * @param referralCode The referral code for the supply action.
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    /** @notice Withdraws a specific amount of an asset from the Aave Pool.
     * @param asset The address of the asset to withdraw.
     * @param amount The amount of the asset to withdraw.
     * @param to The address that will receive the withdrawn assets.
     * @return uint256 The actual amount withdrawn.
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

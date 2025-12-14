// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/** @title IClarityVault
 *  @author louislbd
 *  @notice This interface defines the functions for Clarity's vaults.
 *  @custom:school This interface was developed as part of a school project.
 */
interface IClarityVault is IERC4626 {
    /** @notice Calculate the annual percentage yield (APY) of the vault.
     * @return uint256 The APY value.
     */
    function getAPY() external view returns (uint256);

    /** @notice Calculate the allocation ratios of the vault's assets.
     * @return address[] memory The list of tokens in the vault.
     * @return uint256[] memory The corresponding allocation ratios for each token.
     */
    function getAllocations() external view returns (address[] memory, uint256[] memory);

    /// @notice Pauses the vault in case of emergency, preventing deposits and withdrawals
    function pause() external;

    /// @notice Unpauses the vault
    function unpause() external;

    /// @notice Checks if the vault is currently paused (no deposits/withdrawals allowed)
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/** @title IYoVault
 *  @author louislbd
 *  @notice This interface defines the functions for interacting with the yoProtocol vaults.
 *  @custom:school This interface was developed as part of a school project.
 */
interface IYoVault {
    /** @notice Deposit assets (EURC) and get yoTokens (yoEUR)
     *  @param assets Amount of EURC (6 decimals) to deposit
     *  @param receiver Account to receive yoEUR
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /** @notice Redeem yoTokens (yoEUR) to get back assets (EURC)
     *  @param shares Amount of yoEUR to redeem
     *  @param receiver Where the EURC should go
     *  @param owner Whose yoEUR is being redeemed
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
}

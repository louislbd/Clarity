// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


/** @title ClarityUtils
 *  @author louislbd
 *  @notice This library provides utility functions and constants for the Clarity protocol.
 *  @custom:school This library was developed as part of a school project.
 */
library ClarityUtils {
    // 10,000 basis points = 100%
    uint256 public constant BASIS_POINTS = 1e4;

    // USDC Native on Base
    address public constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // EURC Native on Base
    address public constant EURC_BASE = 0x60a3E35Cc302bFA44Cb288Bc5a4F316Fdb1adb42;

    // Aave V3 Pool on Base
    address public constant AAVE_POOL_BASE = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;

    // YO EUR on Base
    address public constant YO_EUR = 0x50c749aE210D3977ADC824AE11F3c7fd10c871e9;

    /** @notice Calculate fee on raw asset amount.
     *  @param _assets The total asset amount.
     *  @param _feeBP The fee in basis points.
     *  @return uint256 The calculated fee amount.
     */
    function _feeOnRaw(uint256 _assets, uint256 _feeBP) internal pure returns (uint256) {
        return (_assets * _feeBP + BASIS_POINTS - 1) / BASIS_POINTS;
    }

    /** @notice Calculate fee on total asset amount (including fee).
     *  @param _assets The total asset amount including fee.
     *  @param _feeBP The fee in basis points.
     *  @return uint256 The calculated fee amount.
     */
    function _feeOnTotal(uint256 _assets, uint256 _feeBP) internal pure returns (uint256) {
        return (_assets * _feeBP + _feeBP + BASIS_POINTS - 1) / (_feeBP + BASIS_POINTS);
    }
}

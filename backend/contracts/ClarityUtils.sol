// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/** @title ClarityUtils
 *  @author louislbd
 *  @notice This library provides utility functions and constants for the Clarity protocol.
 *  @custom:school This library was developed as part of a school project.
 */
library ClarityUtils {
    using Math for uint256;
    // 10,000 basis points = 100%
    uint256 public constant BASIS_POINTS = 1e4;

    // Aave V3 Pool on Base
    address public constant AAVE_POOL_BASE = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;

    // USDC Native on Base
    address public constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    /** @notice Calculate fee on raw asset amount.
     *  @param _assets The total asset amount.
     *  @param _feeBP The fee in basis points.
     *  @return uint256 The calculated fee amount.
     */
    function _feeOnRaw(uint256 _assets, uint256 _feeBP) internal pure returns (uint256) {
        return _assets.mulDiv(_feeBP, BASIS_POINTS, Math.Rounding.Ceil);
    }

    /** @notice Calculate fee on total asset amount (including fee).
     *  @param _assets The total asset amount including fee.
     *  @param _feeBP The fee in basis points.
     *  @return uint256 The calculated fee amount.
     */
    function _feeOnTotal(uint256 _assets, uint256 _feeBP) internal pure returns (uint256) {
        return _assets.mulDiv(_feeBP, _feeBP + BASIS_POINTS, Math.Rounding.Ceil);
    }
}

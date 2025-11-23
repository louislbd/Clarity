// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library ClarityUtils {
    // Allocation ratios
    uint256 public constant BASIS_POINTS = 1e4;

    // Emergency liquidity pool ratio (basis points, e.g., 2000 = 20%)
    uint256 public constant emergencyLPBP = 2000;

    // Aave V3 Pool on Base
    address public constant AAVE_POOL_BASE = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;

    // USDC Native on Base
    address public constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    function _feeOnRaw(uint256 _assets, uint256 _feeBP) private pure returns (uint256) {
        return _assets.mulDiv(_feeBP, BASIS_POINTS, Math.Rounding.Ceil);
    }

    function _feeOnTotal(uint256 _assets, uint256 _feeBP) private pure returns (uint256) {
        return _assets.mulDiv(_feeBP, _feeBP + BASIS_POINTS, Math.Rounding.Ceil);
    }
}

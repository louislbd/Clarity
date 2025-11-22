// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IClarityVault } from "../interfaces/IClarityVault.sol";


/**
 * @title Safe Vault (Clarity)
 * @author louislbd
 * @notice An ERC-4626 compliant vault implementing a safe yield strategy for Clarity.
 */
contract Safe is ERC4626, Pausable, Ownable, IClarityVault {
    using SafeERC20 for IERC20;
    using Math for uint256;

    struct Allocation {
        address protocol;
        uint256 ratio; // in basis points (e.g., 3270 = 32.7%)
    }

    Allocation[] private allocations;
    uint256 private currentAPY;
    uint256 private constant BASIS_POINTS = 1e4;
    uint256 public entryFeeBP = 100; // 1.0%
    uint256 public exitFeeBP = 50;   // 0.5%
    address public feeRecipient;


    event EmergencyPaused(address indexed caller);
    event EmergencyUnpaused(address indexed caller);
    event AllocationUpdated(address indexed protocol, uint256 newRatio);
    event EntryFeeUpdated(uint256 indexed newFeeBP);
    event ExitFeeUpdated(uint256 indexed newFeeBP);

    error VaultIsPaused();
    error NoAllocationsDefined();
    error InvalidAllocationRatio();
    error FeeTooHigh();

    constructor(
        ERC20 _asset,
        address _owner,
        Allocation[] memory _allocations,
        address _feeRecipient
    )
        ERC4626(_asset)
        ERC20("Clarity Safe LP", "cSAFE")
        Ownable(_owner)
    {
        require(_allocations.length > 0, NoAllocationsDefined());
        uint256 totalRatio;
        for (uint256 i = 0; i < _allocations.length; ++i) {
            allocations.push(_allocations[i]);
            totalRatio += _allocations[i].ratio;
        }
        require(totalRatio == 10000, InvalidAllocationRatio());
        feeRecipient = _feeRecipient;
    }

    function getAllocations()
        external
        view
        override
        returns (address[] memory _tokens, uint256[] memory _ratios)
    {
        uint256 n = allocations.length;
        _tokens = new address[](n);
        _ratios = new uint256[](n);
        for (uint256 i = 0; i < n; ++i) {
            _tokens[i] = allocations[i].protocol;
            _ratios[i] = allocations[i].ratio;
        }
    }

    function setAllocations(Allocation[] memory _newAllocations) external onlyOwner {
        require(_newAllocations.length > 0, NoAllocationsDefined());
        uint256 totalRatio;
        delete allocations;
        for (uint256 i = 0; i < _newAllocations.length; ++i) {
            allocations.push(_newAllocations[i]);
            totalRatio += _newAllocations[i].ratio;
        }
        require(totalRatio == 10000, InvalidAllocationRatio());
        emit AllocationUpdated(address(0), 0);
    }

    function getAPY() external view override returns (uint256) {
        // To be implemented according to vault performance data
        uint256 currentAPY = 12000; // Placeholder value representing 12.00% APY
        return currentAPY;
    }

    function _deposit(
        address _caller,
        address _receiver,
        uint256 _assets,
        uint256 _shares
    ) internal override whenNotPaused {
        uint256 fee = _feeOnTotal(_assets, entryFeeBP);
        super._deposit(_caller, _receiver, _assets, _shares);
        if (fee > 0 && feeRecipient != address(0)) {
            IERC20(asset()).safeTransfer(feeRecipient, fee);
        }
    }

    function _withdraw(
        address _caller,
        address _receiver,
        address _owner,
        uint256 _assets,
        uint256 _shares
    ) internal override whenNotPaused {
        uint256 fee = _feeOnRaw(_assets, exitFeeBP);
        super._withdraw(_caller, _receiver, _owner, _assets, _shares);
        if (fee > 0 && feeRecipient != address(0)) {
            IERC20(asset()).safeTransfer(feeRecipient, fee);
        }
    }

    function _redeem(
        address _caller,
        address _receiver,
        address _owner,
        uint256 _shares,
        uint256 _assets
    ) internal override whenNotPaused {
        uint256 fee = _feeOnTotal(_assets, exitFeeBP);
        super._redeem(_caller, _receiver, _owner, _shares, _assets);
        if (fee > 0 && feeRecipient != address(0)) {
            IERC20(asset()).safeTransfer(feeRecipient, fee);
        }
    }

    function pause() external override onlyOwner {
        _pause();
        emit EmergencyPaused(msg.sender);
    }

    function unpause() external override onlyOwner {
        _unpause();
        emit EmergencyUnpaused(msg.sender);
    }

    function isPaused() external view override returns (bool) {
        return paused();
    }

    function setAPY(uint256 _newAPY) external onlyOwner {
        _currentAPY = _newAPY;
    }

    function setEntryFeeBP(uint256 _newFeeBP) external onlyOwner {
        require(_newFeeBP <= 1000, FeeTooHigh());
        entryFeeBP = _newFeeBP;
        emit EntryFeeUpdated(_newFeeBP);
    }

    function setExitFeeBP(uint256 _newFeeBP) external onlyOwner {
        require(_newFeeBP <= 1000, FeeTooHigh());
        exitFeeBP = _newFeeBP;
        emit ExitFeeUpdated(_newFeeBP);
    }

    function _feeOnRaw(uint256 _assets, uint256 _feeBP) private pure returns (uint256) {
        return _assets.mulDiv(_feeBP, BASIS_POINTS, Math.Rounding.Ceil);
    }

    function _feeOnTotal(uint256 _assets, uint256 _feeBP) private pure returns (uint256) {
        return _assets.mulDiv(_feeBP, _feeBP + BASIS_POINTS, Math.Rounding.Ceil);
    }

    function previewDeposit(uint256 _assets) public view override returns (uint256) {
        uint256 fee = _feeOnTotal(_assets, entryFeeBP);
        return super.previewDeposit(_assets - fee);
    }

    function previewMint(uint256 _shares) public view override returns (uint256) {
        uint256 assets = super.previewMint(_shares);
        return assets + _feeOnRaw(assets, entryFeeBP);
    }

    function previewWithdraw(uint256 _assets) public view override returns (uint256) {
        uint256 fee = _feeOnRaw(_assets, exitFeeBP);
        return super.previewWithdraw(_assets + fee);
    }

    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        uint256 assets = super.previewRedeem(_shares);
        return assets - _feeOnTotal(assets, exitFeeBP);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        require(!paused(), VaultIsPaused());
    }


    // TODO: Implement protocol adapters
}

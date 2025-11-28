// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IClarityVault } from "../interfaces/IClarityVault.sol";
import { IAavePool } from "../interfaces/IAavePool.sol";
import { ClarityUtils } from "../ClarityUtils.sol";


/**
 * @title Safe Vault (Clarity)
 * @author louislbd
 * @notice An ERC-4626 compliant vault implementing a safe yield strategy for Clarity.
 */
contract Safe is ERC4626, Pausable, Ownable, IClarityVault {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /// @notice Allocation structure
    struct Allocation {
        address protocol;
        address asset;
        uint256 ratio;
    }

    Allocation[] private allocations;
    uint256 private currentAPY;
    uint256 public entryFeeBP = 100; // 1.0%
    uint256 public exitFeeBP = 50;   // 0.5%
    address public feeRecipient;


    /// @notice Emitted when the vault is paused
    event EmergencyPaused(address indexed caller);

    /// @notice Emitted when the vault is unpaused
    event EmergencyUnpaused(address indexed caller);

    /// @notice Emitted when the allocation ratios are updated
    event AllocationUpdated(address indexed protocol, uint256 newRatio);

    /// @notice Emitted when the entry fee is updated
    event EntryFeeUpdated(uint256 indexed newFeeBP);

    /// @notice Emitted when the exit fee is updated
    event ExitFeeUpdated(uint256 indexed newFeeBP);

    error VaultIsPaused();
    error NoAllocationsDefined();
    error InvalidAllocationRatio();
    error InvalidProtocolOrAsset();
    error FeeTooHigh();

    /**
     * @notice Constructor for the Safe vault.
     * @param _asset The underlying asset of the vault.
     * @param _owner The owner of the vault.
     * @param _allocations The initial allocation ratios for the vault.
     * @param _feeRecipient The address receiving the fees.
     */
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

    /**
     * @notice Get the current allocation ratios of the vault.
     * @return _tokens memory The list of tokens in the vault.
     * @return _ratios memory The corresponding allocation ratios for each token.
     */
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

    /**
     * @notice Set new allocation ratios for the vault.
     * @param _newAllocations The new allocation ratios.
     */
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

    /**
     * @notice Get the current APY of the vault.
     * @return uint256 The APY value.
     */
    function getAPY() external view override returns (uint256) {
        // To be implemented according to vault performance data
        return 12000;
    }

    /**
     * @notice Deposit assets into the vault.
     * @param _caller The address initiating the deposit.
     * @param _receiver The address receiving the vault shares.
     * @param _assets The amount of assets to deposit.
     * @param _shares The amount of shares to mint.
     */
    function _deposit(
        address _caller,
        address _receiver,
        uint256 _assets,
        uint256 _shares
    ) internal override whenNotPaused {
        uint256 fee = ClarityUtils._feeOnTotal(_assets, entryFeeBP);

        for (uint256 i = 0; i < allocations.length; ++i) {
            Allocation memory alloc = allocations[i];
            // TODO: Use safe math here
            uint256 allocationAmount = (_assets * alloc.ratio) / ClarityUtils.BASIS_POINTS;
            require(allocationAmount <= _assets, InvalidAllocationRatio());

            IERC20(alloc.asset).approve(alloc.protocol, allocationAmount);

            if (alloc.protocol == ClarityUtils.AAVE_POOL_BASE && alloc.asset == ClarityUtils.USDC_BASE) {
                IAavePool(alloc.protocol).supply(alloc.asset, allocationAmount, address(this), 0);
            } else if (alloc.protocol == ClarityUtils.AAVE_POOL_BASE) {
                // Add asset conversion logic here if needed
            } else {
                revert();
            }
        }

        super._deposit(_caller, _receiver, _assets, _shares);

        if (fee > 0 && feeRecipient != address(0)) {
            IERC20(ClarityUtils.USDC_BASE).safeTransfer(feeRecipient, fee);
        }
    }

    /**
     * @notice Withdraw assets from the vault.
     * @param _caller The address initiating the withdrawal.
     * @param _receiver The address receiving the withdrawn assets.
     * @param _owner The address owning the shares being redeemed.
     * @param _assets The amount of assets to withdraw (as per ERC4626 preview logic).
     * @param _shares The amount of shares to burn.
     */
    function _withdraw(
        address _caller,
        address _receiver,
        address _owner,
        uint256 _assets,
        uint256 _shares
    ) internal override whenNotPaused {
        // Unwind allocations proportionally
        for (uint256 i = 0; i < allocations.length; ++i) {
            Allocation memory alloc = allocations[i];
            uint256 allocationAmount = (_assets * alloc.ratio) / ClarityUtils.BASIS_POINTS;
            require(allocationAmount <= _assets, InvalidAllocationRatio());

            if (alloc.protocol == ClarityUtils.AAVE_POOL_BASE && alloc.asset == ClarityUtils.USDC_BASE) {
                IAavePool(alloc.protocol).withdraw(alloc.asset, allocationAmount, address(this));
            } else {
                revert InvalidProtocolOrAsset();
            }
        }

        // Let ERC4626 handle the share burning and bookkeeping
        super._withdraw(_caller, _receiver, _owner, _assets, _shares);

        // Calculate what the vault actually holds in "asset()" after unwind + _withdraw
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        // Cap the realized assets to the minimum of what was requested and what the vault holds
        uint256 realizedAssets = balance < _assets ? balance : _assets;

        // Calculate fees on the effectively realized assets
        uint256 fee = ClarityUtils._feeOnRaw(realizedAssets, exitFeeBP);
        uint256 net = realizedAssets - fee;

        // Distribute fees then send the net to the user
        if (fee > 0 && feeRecipient != address(0)) {
            IERC20(asset()).safeTransfer(feeRecipient, fee);
        }
        if (net > 0) {
            IERC20(asset()).safeTransfer(_receiver, net);
        }
    }


    /**
     * @notice Redeem shares from the vault.
     * @param _shares The amount of shares to burn.
     * @param _receiver The address receiving the withdrawn assets.
     * @param _owner The address owning the shares being redeemed.
     */
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) public override(ERC4626, IERC4626) whenNotPaused returns (uint256 assets) {
        assets = previewRedeem(_shares);
        super._withdraw(msg.sender, _receiver, _owner, _shares, assets);
    }

    /**
     * @notice Pause the vault in case of emergency.
     * @dev Only callable by the owner.
     */
    function pause() external override onlyOwner {
        _pause();
        emit EmergencyPaused(msg.sender);
    }

    /**
     * @notice Unpause the vault in case of emergency.
     * @dev Only callable by the owner.
     */
    function unpause() external override onlyOwner {
        _unpause();
        emit EmergencyUnpaused(msg.sender);
    }

    /**
     * @notice Checks if the vault is currently paused
     * @return bool True if the vault is paused, false otherwise.
     */
    function isPaused() external view override returns (bool) {
        return paused();
    }

    /**
     * @notice Set a new APY for the vault.
     * @dev Only callable by the owner.
     * @param _newAPY The new APY value.
     */
    function setAPY(uint256 _newAPY) external onlyOwner {
        currentAPY = _newAPY;
    }

    /**
     * @notice Set a new entry fee in basis points.
     * @dev Only callable by the owner.
     * @param _newFeeBP The new entry fee in basis points.
     */
    function setEntryFeeBP(uint256 _newFeeBP) external onlyOwner {
        require(_newFeeBP <= 1000, FeeTooHigh());
        entryFeeBP = _newFeeBP;
        emit EntryFeeUpdated(_newFeeBP);
    }

    /**
     * @notice Set a new exit fee in basis points.
     * @dev Only callable by the owner.
     * @param _newFeeBP The new exit fee in basis points.
     */
    function setExitFeeBP(uint256 _newFeeBP) external onlyOwner {
        require(_newFeeBP <= 1000, FeeTooHigh());
        exitFeeBP = _newFeeBP;
        emit ExitFeeUpdated(_newFeeBP);
    }

    /**
     * @notice Preview the amount of shares received for a given asset deposit, accounting for entry fees.
     * @param _assets The amount of assets to deposit.
     * @return uint256 The amount of shares that would be minted.
     */
    function previewDeposit(uint256 _assets) public view override(ERC4626, IERC4626) returns (uint256) {
        uint256 fee = ClarityUtils._feeOnTotal(_assets, entryFeeBP);
        return super.previewDeposit(_assets - fee);
    }

    /**
     * @notice Preview the amount of assets required to mint a given amount of shares, accounting for entry fees.
     * @param _shares The amount of shares to mint.
     * @return uint256 The amount of assets required for the mint.
     */
    function previewMint(uint256 _shares) public view override(ERC4626, IERC4626) returns (uint256) {
        uint256 assets = super.previewMint(_shares);
        return assets + ClarityUtils._feeOnRaw(assets, entryFeeBP);
    }

    /**
     * @notice Preview the amount of shares burned for a given asset withdrawal, accounting for exit fees.
     * @param _assets The amount of assets to withdraw.
     * @return uint256 The amount of shares that would be burned.
     */
    function previewWithdraw(uint256 _assets) public view override(ERC4626, IERC4626) returns (uint256) {
        uint256 fee = ClarityUtils._feeOnRaw(_assets, exitFeeBP);
        return super.previewWithdraw(_assets + fee);
    }

    /**
     * @notice Preview the amount of assets received for a given share redemption, accounting for exit fees.
     * @param _shares The amount of shares to redeem.
     * @return uint256 The amount of assets that would be received.
     */
    function previewRedeem(uint256 _shares) public view override(ERC4626, IERC4626) returns (uint256) {
        uint256 assets = super.previewRedeem(_shares);
        return assets - ClarityUtils._feeOnTotal(assets, exitFeeBP);
    }
}

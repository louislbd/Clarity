// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IClarityVault } from "../interfaces/IClarityVault.sol";
import { IAavePool } from "../interfaces/IAavePool.sol";
import { IYoVault } from "../interfaces/IYoVault.sol";
import { ClarityUtils } from "../ClarityUtils.sol";

/**
 * @title Safe Vault (Clarity)
 * @author louislbd
 * @notice An ERC-4626 compliant vault implementing a safe yield strategy for Clarity.
 * @dev This vault supports ONLY EURC as the underlying asset and allocates it across multiple protocols.
 */
contract Safe is ERC4626, Pausable, Ownable, IClarityVault {
    using SafeERC20 for IERC20;


    /// @notice Allocation structure - simplified for single underlying asset (EURC)
    struct Allocation {
        address protocol;  // e.g., AAVE_POOL_BASE or YO_EUR_BASE
        uint256 ratio;     // Allocation percentage in basis points (out of 10000)
    }

    Allocation[] private allocations;
    uint256 private currentAPY;
    uint256 public entryFeeBP = 100;  // 1.0%
    uint256 public exitFeeBP = 50;    // 0.5%
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
     * @param _asset The underlying asset of the vault (must be EURC).
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
     * @return _tokens memory The list of protocols in the vault.
     * @return _ratios memory The corresponding allocation ratios for each protocol.
     */
    function getAllocations()
        external
        view
        override
        returns (address[] memory _tokens, uint256[] memory _ratios)
    {
        uint256 allocationLength = allocations.length;
        _tokens = new address[](allocationLength);
        _ratios = new uint256[](allocationLength);
        for (uint256 i; i < allocationLength; i++) {
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
        for (uint256 i; i < _newAllocations.length; i++) {
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
    function getAPY() external pure override returns (uint256) {
        return 400;
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

    // ---------- PUBLIC ERC-4626 ENTRYPOINTS ----------

    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver)
        public
        override(ERC4626, IERC4626)
        whenNotPaused
        returns (uint256 shares)
    {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        shares = previewDeposit(assets);

        // Pull assets from caller
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

        // Process deposit: fee handling, protocol allocation, share minting
        _processDeposit(receiver, assets, shares);

        return shares;
    }

    /// @inheritdoc IERC4626
    function mint(uint256 shares, address receiver)
        public
        override(ERC4626, IERC4626)
        whenNotPaused
        returns (uint256 assets)
    {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        assets = previewMint(shares);

        // Pull assets from caller
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

        // Process deposit: fee handling, protocol allocation, share minting
        _processDeposit(receiver, assets, shares);

        return assets;
    }

    /// @inheritdoc IERC4626
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override(ERC4626, IERC4626)
        whenNotPaused
        returns (uint256 shares)
    {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        shares = previewWithdraw(assets);

        // Check allowance
        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                require(allowed >= shares, "ERC4626: insufficient allowance");
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        // Process withdrawal: protocol unwinding, fee handling, share burning
        _processWithdraw(receiver, owner, assets, shares);

        return shares;
    }

    /// @inheritdoc IERC4626
    function redeem(uint256 shares, address receiver, address owner)
        public
        override(ERC4626, IERC4626)
        whenNotPaused
        returns (uint256 assets)
    {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        assets = previewRedeem(shares);

        // Check allowance
        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                require(allowed >= shares, "ERC4626: insufficient allowance");
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        // Process withdrawal: protocol unwinding, fee handling, share burning
        _processWithdraw(receiver, owner, assets, shares);

        return assets;
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

    // ---------- INTERNAL PROCESSING LOGIC ----------

    /**
     * @notice Process a deposit: deduct entry fees, allocate to protocols, mint shares.
     * @param receiver The address receiving the vault shares.
     * @param assets The total assets being deposited.
     * @param shares The amount of shares to mint.
     */
    function _processDeposit(
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal {
        address eurcToken = asset();

        uint256 fee = ClarityUtils._feeOnTotal(assets, entryFeeBP);
        uint256 netAssets = assets - fee;

        if (fee > 0 && feeRecipient != address(0)) {
            IERC20(eurcToken).safeTransfer(feeRecipient, fee);
        }

        for (uint256 i = 0; i < allocations.length; ++i) {
            Allocation memory alloc = allocations[i];
            uint256 allocationAmount =
                (netAssets * alloc.ratio) / ClarityUtils.BASIS_POINTS;
            require(allocationAmount <= netAssets, InvalidAllocationRatio());

            IERC20(eurcToken).approve(alloc.protocol, allocationAmount);

            if (alloc.protocol == ClarityUtils.AAVE_POOL_BASE) {
                IAavePool(alloc.protocol).supply(
                    eurcToken,
                    allocationAmount,
                    address(this),
                    0
                );
            } else if (alloc.protocol == ClarityUtils.YO_EUR_BASE) {
                IYoVault(alloc.protocol).deposit(allocationAmount, address(this));
            } else {
                revert InvalidProtocolOrAsset();
            }

            IERC20(eurcToken).approve(alloc.protocol, 0);
        }

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Process a withdrawal: unwind from protocols, deduct exit fees, burn shares.
     * @param receiver The address receiving the withdrawn assets.
     * @param owner The address owning the shares being redeemed.
     * @param assets The amount of assets to withdraw.
     * @param shares The amount of shares to burn.
     */
    function _processWithdraw(
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal {
        address eurcToken = asset();

        uint256 fee = ClarityUtils._feeOnRaw(assets, exitFeeBP);
        uint256 amountToWithdraw = assets - fee;

        for (uint256 i = 0; i < allocations.length; ++i) {
            Allocation memory alloc = allocations[i];
            uint256 allocationAmount =
                (amountToWithdraw * alloc.ratio) / ClarityUtils.BASIS_POINTS;
            require(allocationAmount <= amountToWithdraw, InvalidAllocationRatio());

            if (alloc.protocol == ClarityUtils.AAVE_POOL_BASE) {
                IAavePool(alloc.protocol).withdraw(
                    eurcToken,
                    allocationAmount,
                    address(this)
                );
            } else if (alloc.protocol == ClarityUtils.YO_EUR_BASE) {
                IYoVault(alloc.protocol).redeem(
                    allocationAmount,
                    address(this),
                    address(this)
                );
            } else {
                revert InvalidProtocolOrAsset();
            }
        }

        if (fee > 0 && feeRecipient != address(0)) {
            IERC20(eurcToken).safeTransfer(feeRecipient, fee);
        }

        if (amountToWithdraw > 0) {
            IERC20(eurcToken).safeTransfer(receiver, amountToWithdraw);
        }

        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}

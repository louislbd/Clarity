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
 * @title Safe Vault (Clarity) - FIXED with proper allocation unwinding
 * @author louislbd
 * @notice An ERC-4626 compliant vault implementing a safe yield strategy for Clarity.
 * @dev This vault supports ONLY EURC as the underlying asset and allocates it across multiple protocols.
 *      Uses a decimals offset of 9 to defend against inflation attacks with virtual shares/assets.
 */
contract Safe is ERC4626, Pausable, Ownable, IClarityVault {
    using SafeERC20 for IERC20;

    /// @notice Allocation structure - simplified for single underlying asset (EURC)
    struct Allocation {
        address protocol;
        uint8 kind;    // 1 = AAVE, 2 = YO
        uint256 ratio;
    }

    Allocation[] private allocations;
    uint256 private currentAPY;
    uint256 public entryFeeBP = 10; // 0.1% entry fee
    uint256 public exitFeeBP = 10;  // 0.1% exit fee
    address public feeRecipient;

    /// @notice Total assets managed across vault and protocols
    uint256 private totalAssetsManaged;

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
        totalAssetsManaged = 0;
    }

    /**
     * @notice Returns the decimals offset used for inflation attack protection.
     * @dev This increases vault decimals by 9, creating virtual shares/assets that make attacks unprofitable.
     *      EURC has 6 decimals → cSAFE has 15 decimals (6 + 9).
     * @return uint8 The decimals offset (9).
     */
    function _decimalsOffset() internal view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @notice Get total assets under management (in vault + in protocols).
     * @dev Overrides ERC4626 to include assets deployed in lending protocols.
     * @return Total assets across vault and all protocol allocations.
     */
    function totalAssets() public view override(ERC4626, IERC4626) returns (uint256) {
        // Assets in vault contract itself
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));


        // Add tracked assets in protocols
        // This is updated whenever assets are deposited/withdrawn
        return totalAssetsManaged + vaultBalance;
    }

    /**
     * @notice Convert shares to assets, properly handling the decimals offset.
     * @dev Override ERC4626 to use simple ratio math instead of broken offset logic.
     * @param shares The amount of shares to convert.
     * @return assets The amount of assets.
     */
    function convertToAssets(uint256 shares)
        public
        view
        virtual
        override(ERC4626, IERC4626)
        returns (uint256)
    {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    /**
     * @notice Convert assets to shares, properly handling the decimals offset.
     * @dev Override ERC4626 to use simple ratio math instead of broken offset logic.
     * @param assets The amount of assets to convert.
     * @return shares The amount of shares.
     */
    function convertToShares(uint256 assets)
        public
        view
        virtual
        override(ERC4626, IERC4626)
        returns (uint256)
    {
        uint256 supply = totalSupply();
        // On first deposit, 1 asset = 1 * 10^offset shares (inflation attack protection)
        return supply == 0 ? assets * 10 ** _decimalsOffset() : (assets * supply) / totalAssets();
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

        // assets = net (user receives this after fees)
        // Compute gross amount to withdraw from protocols
        uint256 feeBP = exitFeeBP;
        uint256 grossAssets = (assets * ClarityUtils.BASIS_POINTS) / (ClarityUtils.BASIS_POINTS - feeBP);

        // Process withdrawal with gross assets
        _processWithdraw(receiver, owner, grossAssets, shares);

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

        // Compute gross assets from shares
        uint256 grossAssets = convertToAssets(shares);

        // Process withdrawal with gross assets
        _processWithdraw(receiver, owner, grossAssets, shares);

        return assets;
    }

    /**
     * @notice Preview the amount of shares received for a given asset deposit, accounting for entry fees.
     * @param _assets The amount of assets to deposit.
     * @return uint256 The amount of shares that would be minted.
     */
    function previewDeposit(uint256 _assets) public view override(ERC4626, IERC4626) returns (uint256) {
        uint256 fee = ClarityUtils._feeOnTotal(_assets, entryFeeBP);
        uint256 netAssets = _assets - fee;
        // Use custom convertToShares, not super.previewDeposit
        return convertToShares(netAssets);
    }

    /**
     * @notice Preview the amount of assets required to mint a given amount of shares, accounting for entry fees.
     * @param _shares The amount of shares to mint.
     * @return uint256 The amount of assets required for the mint.
     */
    function previewMint(uint256 _shares) public view override(ERC4626, IERC4626) returns (uint256) {
        // Get assets needed for the shares
        uint256 assets = convertToAssets(_shares);
        // Add entry fee on top
        return assets + ClarityUtils._feeOnRaw(assets, entryFeeBP);
    }

    /**
     * @notice Preview the amount of shares burned for a given asset withdrawal, accounting for exit fees.
     * @param _assets The amount of assets to withdraw (net).
     * @return uint256 The amount of shares that would be burned.
     */
    function previewWithdraw(uint256 _assets) public view override(ERC4626, IERC4626) returns (uint256) {
        // User wants net _assets
        // Gross assets = net / (1 - exitFeeBP)
        uint256 feeBP = exitFeeBP;
        uint256 grossAssets = (_assets * ClarityUtils.BASIS_POINTS) / (ClarityUtils.BASIS_POINTS - feeBP);
        // Convert gross assets to shares needed
        return convertToShares(grossAssets);
    }

    /**
     * @notice Preview assets received when redeeming shares, net of exit fees.
     * @param _shares The amount of shares to redeem.
     * @return uint256 The amount of assets received (after fees).
     */
    function previewRedeem(uint256 _shares) public view override(ERC4626, IERC4626) returns (uint256) {
        // Get gross assets from shares
        uint256 grossAssets = convertToAssets(_shares);
        // Deduct exit fee
        uint256 feeAmount = ClarityUtils._feeOnTotal(grossAssets, exitFeeBP);
        return grossAssets - feeAmount;
    }

    /**
     * @notice Maximum amount of assets that can be withdrawn by owner, accounting for exit fees.
     * @param owner The address owning the shares.
     * @return uint256 The maximum amount of assets (net of fees) that can be withdrawn.
     */
    function maxWithdraw(address owner) public view override(ERC4626, IERC4626) returns (uint256) {
        uint256 shares = balanceOf(owner);
        if (shares == 0) return 0;

        // Convert shares to gross assets using correct conversion
        uint256 grossAssets = convertToAssets(shares);

        // Deduct exit fee to get net assets user receives
        uint256 netAssets = grossAssets - ClarityUtils._feeOnTotal(grossAssets, exitFeeBP);

        return netAssets;
    }

    /**
     * @notice Maximum amount of shares that can be redeemed by owner.
     * @param owner The address owning the shares.
     * @return uint256 The maximum amount of shares that can be redeemed.
     */
    function maxRedeem(address owner) public view override(ERC4626, IERC4626) returns (uint256) {
        return balanceOf(owner);
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
            uint256 allocationAmount = (netAssets * alloc.ratio) / ClarityUtils.BASIS_POINTS;

            require(allocationAmount <= netAssets, InvalidAllocationRatio());

            IERC20(eurcToken).approve(alloc.protocol, allocationAmount);

            if (alloc.kind == 1) {
                IAavePool(alloc.protocol).supply(
                    eurcToken,
                    allocationAmount,
                    address(this),
                    0
                );
            } else if (alloc.kind == 2) {
                IYoVault(alloc.protocol).deposit(allocationAmount, address(this));
            } else {
                revert InvalidProtocolOrAsset();
            }
            IERC20(eurcToken).approve(alloc.protocol, 0);
        }
        // Update total assets managed
        totalAssetsManaged += netAssets;
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Process a withdrawal: unwind from protocols, deduct exit fees, burn shares.
     * @param receiver The address receiving the withdrawn assets (net, after fees).
     * @param owner The address owning the shares being redeemed.
     * @param grossAssets The total amount of assets to unwind from protocols (gross, includes fees).
     * @param shares The amount of shares to burn.
     */
    function _processWithdraw(
        address receiver,
        address owner,
        uint256 grossAssets,
        uint256 shares
    ) internal {
        address eurcToken = asset();
        // Cap grossAssets to not exceed what's actually deployed
        // This handles rounding edge cases where grossAssets > totalAssetsManaged
        uint256 amountToUnwind = grossAssets > totalAssetsManaged ? totalAssetsManaged : grossAssets;
        // Compute fee and net from the actual amount being unwound
        uint256 fee = ClarityUtils._feeOnTotal(amountToUnwind, exitFeeBP);
        uint256 netAssets = amountToUnwind - fee;

        for (uint256 i = 0; i < allocations.length; ++i) {
            Allocation memory alloc = allocations[i];
            uint256 allocationAmount =
                (amountToUnwind * alloc.ratio) / ClarityUtils.BASIS_POINTS;
            require(allocationAmount <= amountToUnwind, InvalidAllocationRatio());

            if (alloc.kind == 1) {
                IAavePool(alloc.protocol).withdraw(
                    eurcToken,
                    allocationAmount,
                    address(this)
                );
            } else if (alloc.kind == 2) {
                IYoVault(alloc.protocol).redeem(
                    allocationAmount,
                    address(this),
                    address(this)
                );
            } else {
                revert InvalidProtocolOrAsset();
            }
        }

        // Update total assets managed by actual unwound amount
        totalAssetsManaged -= amountToUnwind;

        if (fee > 0 && feeRecipient != address(0)) {
            IERC20(eurcToken).safeTransfer(feeRecipient, fee);
        }
        if (netAssets > 0) {
            IERC20(eurcToken).safeTransfer(receiver, netAssets);
        }

        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, amountToUnwind, shares);
    }
}

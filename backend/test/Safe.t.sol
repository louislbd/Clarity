// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { Safe } from "../contracts/vaults/Safe.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAavePool } from "../contracts/interfaces/IAavePool.sol";
import { IYoVault } from "../contracts/interfaces/IYoVault.sol";
import { ClarityUtils } from "../contracts/ClarityUtils.sol";

/// @dev Simple test ERC20 with 6 decimals for USDC-like behavior
contract TestERC20 is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_)
        ERC20(name_, symbol_)
    {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Minimal mock Aave pool that only tracks balances, no ERC20 transfers.
/// Safe handles all actual token transfers in tests.
contract MockAavePool is IAavePool {
    event Supplied(address asset, uint256 amount, address onBehalfOf, uint16 referralCode);
    event Withdrawn(address asset, uint256 amount, address to);

    // simple accounting: asset => balance
    mapping(address => uint256) public balances;

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external override {
        require(amount > 0, "amount=0");
        // Just bump internal accounting; do NOT move tokens
        balances[asset] += amount;
        emit Supplied(asset, amount, onBehalfOf, referralCode);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external override returns (uint256) {
        require(amount > 0, "amount=0");
        require(balances[asset] >= amount, "insufficient mock balance");

        // Decrease accounting only; Safe will handle actual transfers
        balances[asset] -= amount;

        emit Withdrawn(asset, amount, to);
        return amount;
    }
}

contract MockYoVault is IYoVault {
    uint256 public totalAssetsStored;
    uint256 public totalShares;
    address public immutable underlying; // EURC address (for reference only)

    constructor(address _underlying) {
        underlying = _underlying;
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        require(assets > 0, "amount=0");
        // Do NOT transfer tokens; Safe already moved them
        shares = assets;
        totalAssetsStored += assets;
        totalShares += shares;
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        require(shares > 0, "shares=0");
        require(totalShares >= shares, "insufficient yoShares");

        assets = shares;
        totalShares -= shares;
        totalAssetsStored -= assets;
        // Do NOT transfer tokens; Safe will handle balances/fees
    }

    function previewDeposit(uint256 assets) external pure returns (uint256) {
        return assets;
    }

    function previewRedeem(uint256 shares) external pure returns (uint256) {
        return shares;
    }
}

contract SafeVaultTest is Test {
    TestERC20 internal usdc;
    MockAavePool internal aavePool;
    Safe internal vault;

    address internal owner = address(0xA11CE);
    address internal user = address(0xBEEF);
    address internal feeRecipient = address(0xFEE5);

    uint256 internal constant INITIAL_USER_USDC = 1_000_000e6; // 1,000,000 USDC (6 decimals)

    function setUp() public {
        // USDC + Aave setup
        TestERC20 realUsdcImpl = new TestERC20("Test USDC", "tUSDC", 6);
        MockAavePool realAaveImpl = new MockAavePool();

        address usdcAddr = ClarityUtils.USDC_BASE;
        address aaveAddr = ClarityUtils.AAVE_POOL_BASE;

        vm.etch(usdcAddr, address(realUsdcImpl).code);
        vm.etch(aaveAddr, address(realAaveImpl).code);

        usdc = TestERC20(usdcAddr);
        aavePool = MockAavePool(aaveAddr);

        // USDC-based Safe for Aave tests
        Safe.Allocation[] memory allocs = new Safe.Allocation[](1);
        allocs[0] = Safe.Allocation({
            protocol: aaveAddr,
            kind: 1,
            ratio: 10_000
        });

        vm.prank(owner);
        vault = new Safe(
            ERC20(usdcAddr),
            owner,
            allocs,
            feeRecipient
        );

        usdc.mint(user, INITIAL_USER_USDC);

        // EURC + Yo setup
        TestERC20 realEurcImpl = new TestERC20("Test EURC", "tEURC", 6);

        address eurcAddr = ClarityUtils.EURC_BASE;
        address yoAddr   = ClarityUtils.YO_EUR_BASE;

        // Install EURC code at its canonical address
        vm.etch(eurcAddr, address(realEurcImpl).code);

        // Construct Yo vault with the FINAL EURC address as underlying
        MockYoVault realYoImpl = new MockYoVault(eurcAddr);
        vm.etch(yoAddr, address(realYoImpl).code);
    }

    function testInitialState() public view {
        assertEq(vault.asset(), address(usdc), "asset mismatch");
        assertEq(vault.entryFeeBP(), 100, "entry fee");
        assertEq(vault.exitFeeBP(), 50, "exit fee");

        (address[] memory protocols, uint256[] memory ratios) = vault.getAllocations();
        assertEq(protocols.length, 1);
        assertEq(ratios.length, 1);
        assertEq(protocols[0], address(aavePool));
        assertEq(ratios[0], 10_000);
    }

    function testDepositRoutesToAaveAndChargesFee() public {
        uint256 amount = 1_000e6; // 1,000 USDC

        vm.startPrank(user);
        usdc.approve(address(vault), amount);

        uint256 expectedShares = vault.previewDeposit(amount);
        assertGt(expectedShares, 0, "expectedShares should be > 0");

        uint256 shares = vault.deposit(amount, user);
        vm.stopPrank();

        assertEq(shares, expectedShares, "shares mismatch");
        assertEq(vault.balanceOf(user), shares, "user shares balance");

        uint256 fee = ClarityUtils._feeOnTotal(amount, vault.entryFeeBP());
        uint256 netAssets = amount - fee;

        // Fee goes to recipient
        assertEq(usdc.balanceOf(feeRecipient), fee, "fee recipient USDC balance");

        // Aave should have received netAssets
        assertEq(aavePool.balances(address(usdc)), netAssets, "Aave mock balance should equal netAssets");
    }

    function testWithdrawUnwindsFromAaveAndChargesFee() public {
        uint256 amount = 1_000e6;

        // First deposit
        vm.startPrank(user);
        usdc.approve(address(vault), amount);
        vault.deposit(amount, user);
        vm.stopPrank();

        uint256 withdrawAssets = 500e6;

        vm.startPrank(user);
        uint256 expectedSharesBurned = vault.previewWithdraw(withdrawAssets);
        uint256 burnedShares = vault.withdraw(withdrawAssets, user, user);
        vm.stopPrank();

        assertEq(burnedShares, expectedSharesBurned, "burned shares mismatch");

        // Fee recipient should have entry fee + exit fee
        uint256 feeRecipientBal = usdc.balanceOf(feeRecipient);
        assertGt(feeRecipientBal, 0, "fee recipient should have fees after withdraw");

        // User should have received the net amount
        assertGt(usdc.balanceOf(user), 0, "user should have received assets");
    }

    function testRedeemUsesPreviewAndRespectsFees() public {
        uint256 amount = 1_000e6;

        // Deposit
        vm.startPrank(user);
        usdc.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, user);
        vm.stopPrank();

        // Redeem all shares
        vm.startPrank(user);
        uint256 previewAssets = vault.previewRedeem(shares);
        uint256 assetsOut = vault.redeem(shares, user, user);
        vm.stopPrank();

        assertEq(assetsOut, previewAssets, "redeem assets mismatch");

        // Fee recipient should have entry fee + exit fee
        uint256 feeRecipientBal = usdc.balanceOf(feeRecipient);
        assertGt(feeRecipientBal, 0, "fee recipient should have collected fees");

        // User should have recovered assets after paying fees
        uint256 userBal = usdc.balanceOf(user);
        assertLt(userBal, INITIAL_USER_USDC, "user balance should be reduced by fees");
        assertGt(userBal, 0, "user should have recovered some assets");
    }

    function testPauseBlocksDepositWithdrawRedeem() public {
        // Owner pauses
        vm.prank(owner);
        vault.pause();
        assertTrue(vault.isPaused(), "vault should be paused");

        vm.startPrank(user);
        usdc.approve(address(vault), 1_000e6);

        vm.expectRevert(); // whenNotPaused in deposit path
        vault.deposit(1_000e6, user);

        vm.expectRevert();
        vault.withdraw(0, user, user);

        vm.expectRevert();
        vault.redeem(0, user, user);
        vm.stopPrank();
    }

    function testSetFeesAndAPYOnlyOwner() public {
        // Non-owner cannot set
        vm.prank(user);
        vm.expectRevert();
        vault.setEntryFeeBP(200);

        vm.prank(user);
        vm.expectRevert();
        vault.setExitFeeBP(200);

        vm.prank(user);
        vm.expectRevert();
        vault.setAPY(15000);

        // Owner can set
        vm.prank(owner);
        vault.setEntryFeeBP(200);
        assertEq(vault.entryFeeBP(), 200, "entry fee should be updated");

        vm.prank(owner);
        vault.setExitFeeBP(200);
        assertEq(vault.exitFeeBP(), 200, "exit fee should be updated");

        vm.prank(owner);
        vault.setAPY(15000);
        uint256 apy = vault.getAPY();
        assertEq(apy, 400, "getAPY should return constant 400");
    }

    function testSetAllocationsOnlyOwnerAndValidSum() public {
        Safe.Allocation[] memory badAllocs = new Safe.Allocation[](1);
        badAllocs[0] = Safe.Allocation({
            protocol: address(aavePool),
            kind: 1,
            ratio: 5_000
        });

        // non-owner
        vm.prank(user);
        vm.expectRevert();
        vault.setAllocations(badAllocs);

        // owner but invalid ratio sum (not 10000)
        vm.prank(owner);
        vm.expectRevert();
        vault.setAllocations(badAllocs);

        Safe.Allocation[] memory goodAllocs = new Safe.Allocation[](2);
        goodAllocs[0] = Safe.Allocation({
            protocol: address(aavePool),
            kind: 1,
            ratio: 6_000
        });
        goodAllocs[1] = Safe.Allocation({
            protocol: address(aavePool),
            kind: 1,
            ratio: 4_000
        });

        vm.prank(owner);
        vault.setAllocations(goodAllocs);

        (address[] memory protocols, uint256[] memory ratios) = vault.getAllocations();
        assertEq(protocols.length, 2, "should have 2 allocations");
        assertEq(ratios.length, 2, "should have 2 ratios");
        assertEq(ratios[0] + ratios[1], 10_000, "ratios should sum to 10000");
    }

    function testDepositWithEURCAndYoVaultAlloc() public {
        TestERC20 eurc = TestERC20(ClarityUtils.EURC_BASE);
        MockYoVault yoVault = MockYoVault(ClarityUtils.YO_EUR_BASE);

        Safe.Allocation[] memory allocs = new Safe.Allocation[](1);
        allocs[0] = Safe.Allocation({
            protocol: ClarityUtils.YO_EUR_BASE,
            kind: 2,
            ratio:    10_000
        });

        vm.prank(owner);
        Safe eurcVault = new Safe(
            ERC20(ClarityUtils.EURC_BASE),
            owner,
            allocs,
            feeRecipient
        );

        uint256 amount = 1_000e6;
        eurc.mint(user, amount);

        vm.startPrank(user);
        eurc.approve(address(eurcVault), amount);
        uint256 expectedShares = eurcVault.previewDeposit(amount);
        uint256 shares = eurcVault.deposit(amount, user);
        vm.stopPrank();

        assertEq(shares, expectedShares, "EURC deposit: shares mismatch");
        assertEq(eurcVault.balanceOf(user), shares, "EURC deposit: user shares");

        uint256 fee = ClarityUtils._feeOnTotal(amount, eurcVault.entryFeeBP());
        uint256 netAssets = amount - fee;

        // Fee should be transferred to fee recipient
        assertEq(eurc.balanceOf(feeRecipient), fee, "EURC deposit: fee recipient balance");

        // YoVault should have received netAssets
        assertEq(yoVault.totalAssetsStored(), netAssets, "EURC deposit: yoVault should have netAssets");
    }

    function testWithdrawWithEURCAndYoVaultAlloc() public {
        TestERC20 eurc = TestERC20(ClarityUtils.EURC_BASE);
        MockYoVault yoVault = MockYoVault(ClarityUtils.YO_EUR_BASE);

        Safe.Allocation[] memory allocs = new Safe.Allocation[](1);
        allocs[0] = Safe.Allocation({
            protocol: ClarityUtils.YO_EUR_BASE,
            kind: 2,
            ratio:    10_000
        });

        vm.prank(owner);
        Safe eurcVault = new Safe(
            ERC20(ClarityUtils.EURC_BASE),
            owner,
            allocs,
            feeRecipient
        );

        uint256 amount = 1_000e6;
        eurc.mint(user, amount);

        // Deposit full amount
        vm.startPrank(user);
        eurc.approve(address(eurcVault), amount);
        eurcVault.deposit(amount, user);
        vm.stopPrank();

        uint256 withdrawAssets = 500e6;
        uint256 expectedSharesBurned = eurcVault.previewWithdraw(withdrawAssets);

        uint256 beforeUser = eurc.balanceOf(user);
        uint256 beforeFee  = eurc.balanceOf(feeRecipient);
        uint256 beforeYoAccounted = yoVault.totalAssetsStored();

        vm.startPrank(user);
        uint256 burnedShares = eurcVault.withdraw(withdrawAssets, user, user);
        vm.stopPrank();

        assertEq(burnedShares, expectedSharesBurned, "EURC withdraw: burned shares mismatch");

        uint256 afterUser = eurc.balanceOf(user);
        uint256 afterFee  = eurc.balanceOf(feeRecipient);
        uint256 afterYoAccounted = yoVault.totalAssetsStored();

        // User receives assets after fees
        assertGt(afterUser, beforeUser, "EURC withdraw: user should receive assets");

        // Fee recipient gains exit fees
        assertGt(afterFee, beforeFee, "EURC withdraw: fee recipient should gain fees");

        // YoVault accounting decreases as we unwind
        assertLt(afterYoAccounted, beforeYoAccounted, "EURC withdraw: yoVault assets should decrease");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { RolesAuthority, Authority } from "solmate/auth/authorities/RolesAuthority.sol";
import { ERC4626, ERC20 } from "solmate/mixins/ERC4626.sol";

//////////////////////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////////////////////

/// @notice Thrown if the yield asset address is the zero address.
error YieldAssetZeroAddress();

/// @notice Thrown if the amount of yield withdrawn is more than the available yield.
/// @param amount The amount of yield withdrawn
/// @param availableYield The available yield
error AmountMoreThanYield(uint256 amount, uint256 availableYield);

//////////////////////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////////////////////

/// @notice Emitted when yield is withdrawn by a manager address.
/// @param caller The caller of the function
/// @param to The receiver of the withdrawal
/// @param amount The amount of yield withdrawn
event WithdrawYield(address indexed caller, address indexed to, uint256 amount);

/**
 * @notice This contract takes deposits of a yield-bearing asset. Each depositor keeps
 * control of their initial deposit while the contract managers can withdraw the yield 
 * accrued.
 * @author PayPhone Team
 */
contract YieldVaultSponsor is RolesAuthority, ERC4626 {

    ////////////////////////////////////////////////////////////////////////////////////////
    // Constants
    ////////////////////////////////////////////////////////////////////////////////////////

    uint8 public constant MANAGER_ROLE = 0;

    ////////////////////////////////////////////////////////////////////////////////////////
    // Variables
    ////////////////////////////////////////////////////////////////////////////////////////

    ERC20 public immutable yieldAsset;

    ////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////////////

    constructor(
        ERC20 _yieldAsset,
        string memory _name,
        string memory _symbol
    ) RolesAuthority(msg.sender, Authority(this)) ERC4626(_yieldAsset, _name, _symbol) {
        if (address(0) == address(_yieldAsset)) revert YieldAssetZeroAddress();
        yieldAsset = _yieldAsset;
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    // ERC4626 Overrides
    ////////////////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc ERC4626
    function totalAssets() public view override returns (uint256) {
        return yieldAsset.balanceOf(address(this));
    }


    /// NOTE: The following functions are overridden since each share is equal to one asset:

    /// @inheritdoc ERC4626
    function convertToShares(uint256 assets) public pure override returns (uint256) {
        return assets;
    }

    /// @inheritdoc ERC4626
    function convertToAssets(uint256 shares) public pure override returns (uint256) {
        return shares;
    }

    /// @inheritdoc ERC4626
    function previewMint(uint256 shares) public pure override returns (uint256) {
        return shares;
    }

    /// @inheritdoc ERC4626
    function previewWithdraw(uint256 assets) public pure override returns (uint256) {
        return assets;
    }


    /// NOTE: The following functions are overridden to prevent deposits and mints if the
    /// vault has less assets than shares.

    /// @inheritdoc ERC4626
    function maxDeposit(address) public view override returns (uint256) {
        return totalAssets() < totalSupply ? 0 : type(uint256).max;
    }

    /// @inheritdoc ERC4626
    function maxMint(address) public view override returns (uint256) {
        return totalAssets() < totalSupply ? 0 : type(uint256).max;
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    // Manager Functions
    ////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the available yield that can be withdrawn.
    /// @return The available yield that can be withdrawn
    function availableYield() public view virtual returns (uint256) {
        uint256 _assets = totalAssets();
        uint256 _shares = totalSupply;
        if (_assets < _shares) {
            return 0;
        } else {
            unchecked {
                return _assets - _shares;
            }
        }
    }

    /// @notice Withdraws yield from the vault to the receiver address.
    /// @dev Requires sender to have manager role.
    function withdrawYield(address receiver, uint256 amount) external requiresAuth() {
        if (amount > availableYield()) {
            revert AmountMoreThanYield(amount, availableYield());
        }
        yieldAsset.transfer(receiver, amount);
        emit WithdrawYield(msg.sender, receiver, amount);
    }

}

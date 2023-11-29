// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ERC20 } from "./token/ERC20.sol";
import { ERC4626 } from "solmate/mixins/ERC4626.sol";

/// @notice This contract loosely simulates a yield bearing asset that increases with a predefined rate.
contract MockYieldToken is ERC20 {

    uint256 public _balanceScalar = 1e18;
    uint256 public _lastScalarUpdateHour;
    uint256 public immutable hourlyMintRate;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _hourlyMintRate // 18 decimal mint rate (ex: 3e16 is 3%)
    ) ERC20(_name, _symbol) {
        _lastScalarUpdateHour = block.timestamp / 3600;
        hourlyMintRate = _hourlyMintRate;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function mintAndDeposit(ERC4626 vault, address to, uint256 amount) external {
        require(address(vault.asset()) == address(this), "asset incompatible");
        _mint(address(this), amount);
        uint256 _balance = balanceOf(address(this));
        _approve(address(this), address(vault), _balance);
        vault.deposit(_balance, to); 
    }

    function balanceOf(address account) public view override returns (uint256) {
        (uint256 _scalar, ) = balanceScalar();
        return (_balances[account] * _scalar) / 1e18;
    }

    function totalSupply() public view override returns (uint256) {
        (uint256 _scalar, ) = balanceScalar();
        return (_totalSupply * _scalar) / 1e18;
    }

    function balanceScalar() public view returns (uint256 balanceScalar_, uint256 scalarUpdateHour) {
        scalarUpdateHour = block.timestamp / 3600;
        uint256 _hoursPassed = scalarUpdateHour - _lastScalarUpdateHour;
        balanceScalar_ = (_balanceScalar * (1e18 + hourlyMintRate * _hoursPassed)) / 1e18;
    }

    function _updateBalanceScalar() internal returns (uint256) {
        (uint256 balanceScalar_, uint256 scalarUpdateHour) = balanceScalar();
        _balanceScalar = balanceScalar_;
        _lastScalarUpdateHour = scalarUpdateHour;
        return balanceScalar_;
    }

    /******************
     * ERC20 Overrides:
     ******************/

    function _update(address from, address to, uint256 value) internal override {

        // Update balance scalar and adjust value
        uint256 balanceScalar_ = _updateBalanceScalar();
        uint256 scaledValue = (value * 1e18) / balanceScalar_;

        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += scaledValue;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < scaledValue) {
                revert ERC20InsufficientBalance(from, fromBalance, scaledValue);
            }
            unchecked {
                // Overflow not possible: scaledValue <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - scaledValue;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: scaledValue <= totalSupply or scaledValue <= fromBalance <= totalSupply.
                _totalSupply -= scaledValue;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + scaledValue is at most totalSupply, which we know fits into a uint256.
                _balances[to] += scaledValue;
            }
        }

        emit Transfer(from, to, value);
    }

}
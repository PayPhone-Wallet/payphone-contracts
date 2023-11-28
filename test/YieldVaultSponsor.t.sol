// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import { YieldVaultSponsor } from "src/YieldVaultSponsor.sol";
import { MockYieldToken } from "src/MockYieldToken.sol";

contract TestYieldVaultSponsor is Test {
    YieldVaultSponsor yieldVaultSponsor;
    MockYieldToken yieldToken;

    function setUp() public {
        vm.warp(0);
        yieldToken = new MockYieldToken("Mock USD", "mUSD", 34e11);
        yieldVaultSponsor = new YieldVaultSponsor(yieldToken, "PayPhone USD", "payUSD");
    }

    function test() public {
        vm.warp(0);
        
        // Mint yield token
        yieldToken.mint(address(this), 100e18);
        uint256 _balance = yieldToken.balanceOf(address(this));

        // Deposit to vault
        yieldToken.approve(address(yieldVaultSponsor), _balance);
        uint256 received = yieldVaultSponsor.deposit(_balance, address(this));
        assertEq(received, _balance);
        assertEq(yieldVaultSponsor.balanceOf(address(this)), _balance);

        // Wait for yield
        vm.warp(1 days);
        uint256 yield = (_balance * 34e11 * 24) / 1e18;
        assertEq(yieldVaultSponsor.availableYield(), yield);
        assertEq(yieldVaultSponsor.totalSupply(), _balance);
        assertEq(yieldVaultSponsor.totalAssets(), yield + _balance);

        // Harvest Yield
        yieldVaultSponsor.withdrawYield(address(1), yield / 2);
        assertApproxEqAbs(yieldToken.balanceOf(address(1)), yield / 2, 1);
        assertEq(yieldVaultSponsor.availableYield(), yield / 2);

        yieldVaultSponsor.withdrawYield(address(1), yield / 2);
        assertApproxEqAbs(yieldToken.balanceOf(address(1)), yield, 1);

        assertEq(yieldVaultSponsor.balanceOf(address(this)), _balance);
        assertEq(yieldVaultSponsor.totalSupply(), _balance);
        assertEq(yieldVaultSponsor.totalAssets(), _balance);

    }
}

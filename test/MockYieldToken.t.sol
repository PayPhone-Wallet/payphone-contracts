// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import "src/MockYieldToken.sol";

contract TestMockYieldToken is Test {
    MockYieldToken mockYieldToken;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        mockYieldToken = new MockYieldToken("mockUSD", "mUSD", 34e11); // ~3% APY hourly
    }

    function test() public {
        vm.warp(0);

        // mint
        vm.expectEmit(true, true, false, false);
        emit Transfer(address(0), address(this), 100e18);
        mockYieldToken.mint(address(this), 100e18);
        assertApproxEqAbs(mockYieldToken.balanceOf(address(this)), 100e18, 1);

        // grow
        vm.warp(1 days);
        uint256 _balance = mockYieldToken.balanceOf(address(this));
        assertGt(_balance, 0);
        assertEq(_balance, (100e18 * (1e18 + 24 * 34e11)) / 1e18);
        vm.expectEmit();
        emit Transfer(address(this), address(1), _balance);
        mockYieldToken.transfer(address(1), _balance);
        assertEq(mockYieldToken.balanceOf(address(1)), _balance);
        assertEq(mockYieldToken.totalSupply(), _balance);

        // mint again
        mockYieldToken.mint(address(this), 100e18);
        assertApproxEqAbs(mockYieldToken.balanceOf(address(this)), 100e18, 1);
        assertApproxEqAbs(mockYieldToken.totalSupply(), _balance + 100e18, 1);

    }

}
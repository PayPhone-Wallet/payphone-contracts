// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import "src/YieldVaultSponsor.sol";

contract TestYieldVaultSponsor is Test {
    YieldVaultSponsor yieldVaultSponsor;

    function setUp() public {
        // yieldVaultSponsor = new YieldVaultSponsor();
    }

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }
}

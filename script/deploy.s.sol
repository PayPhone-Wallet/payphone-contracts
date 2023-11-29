// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";

import { YieldVaultSponsor } from "src/YieldVaultSponsor.sol";
import { MockYieldToken } from "src/MockYieldToken.sol";

contract Deploy is Script {

    function run() public {
        vm.startBroadcast();
        MockYieldToken token = new MockYieldToken("mockUSD", "mUSD", 34e11);
        YieldVaultSponsor vault = new YieldVaultSponsor(token, "PayPhone USD", "payUSD");
        vm.stopBroadcast();
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/FTHCore.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        
        FTHCore token = new FTHCore();
        
        console.log("FTH Core deployed at:", address(token));
        console.log("Owner:", token.owner());
        console.log("Name:", token.name());
        console.log("Symbol:", token.symbol());
        
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DappEventXFactory.sol";
import "../src/Ticket1155.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        Ticket1155 ticket = new Ticket1155(
            0xYourVRFCoordinator, // e.g., Sepolia VRF
            YourSubscriptionId,
            0xYourKeyHash
        );

        DappEventXFactory factory = new DappEventXFactory(address(ticket));
        ticket.grantRole(ticket.DEFAULT_ADMIN_ROLE(), address(factory));

        vm.stopBroadcast();
    }
}

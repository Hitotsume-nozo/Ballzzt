// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DappEventXFactory.sol";
import "../src/Ticket1155.sol";

contract EventXTest is Test {
    Ticket1155 ticket;
    DappEventXFactory factory;

    function setUp() public {
        ticket = new Ticket1155(address(0), 0, bytes32(0)); // mocked for local
        factory = new DappEventXFactory(address(ticket));
    }

    function testFactoryCreatesEvent() public {
        address org = address(1);
        address eventAddr = factory.createEvent(org, block.timestamp + 1 days);
        assert(eventAddr != address(0));
    }
}

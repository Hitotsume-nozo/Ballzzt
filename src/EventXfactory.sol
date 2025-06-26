// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract DappEventXFactory is AccessControl {
    bytes32 public constant FACTORY_ADMIN = keccak256("FACTORY_ADMIN");

    Ticket1155 public ticketContract;
    address[] public events;

    event EventCreated(address indexed eventInstance, address organizer);

    constructor(address _ticket1155) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ticketContract = Ticket1155(_ticket1155);
    }

    function createEvent(address organizer, uint256 date) external onlyRole(FACTORY_ADMIN) returns (address) {
        EventInstance newEvent = new EventInstance(organizer, address(ticketContract), organizer, date);
        events.push(address(newEvent));
        ticketContract.grantRole(ticketContract.MINTER_ROLE(), address(newEvent));
        emit EventCreated(address(newEvent), organizer);
        return address(newEvent);
    }

    function getAllEvents() external view returns (address[] memory) {
        return events;
    }
}
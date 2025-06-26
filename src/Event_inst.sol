// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract EventInstance is AccessControl, ReentrancyGuard, KeeperCompatibleInterface {
    bytes32 public constant ORGANIZER_ROLE = keccak256("ORGANIZER_ROLE");

    struct TicketTier {
        uint256 price;
        uint256 tokenId;
        uint256 supply;
        uint256 sold;
    }

    Ticket1155 public ticketContract;
    mapping(string => TicketTier) public tiers;
    string[] public tierNames;
    address public treasury;
    uint256 public eventDate;
    bool public cancelled;
    bool public payoutClaimed;
    mapping(address => mapping(string => uint256)) public purchases;
    mapping(address => uint256) public pendingRefunds;
    uint256 public totalRevenue;

    constructor(
        address organizer,
        address _ticketContract,
        address _treasury,
        uint256 _eventDate
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORGANIZER_ROLE, organizer);
        ticketContract = Ticket1155(_ticketContract);
        treasury = _treasury;
        eventDate = _eventDate;
    }

    function addTier(
        string memory name,
        uint256 price,
        uint256 supply,
        string memory uri
    ) external onlyRole(ORGANIZER_ROLE) {
        require(tiers[name].tokenId == 0, "Tier exists");
        uint256 tokenId = ticketContract.mintWithRandomness(address(this), block.number, uri);
        tiers[name] = TicketTier(price, tokenId, supply, 0);
        tierNames.push(name);
    }

    function buy(string memory tier, uint256 quantity) external payable nonReentrant {
        TicketTier storage t = tiers[tier];
        require(!cancelled, "Event cancelled");
        require(t.sold + quantity <= t.supply, "Sold out");
        uint256 cost = quantity * t.price;
        require(msg.value >= cost, "Insufficient payment");
        t.sold += quantity;
        totalRevenue += cost;
        purchases[msg.sender][tier] += quantity;
        ticketContract.safeTransferFrom(address(this), msg.sender, t.tokenId, quantity, "");
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function cancel() external onlyRole(ORGANIZER_ROLE) {
        require(!cancelled, "Already cancelled");
        cancelled = true;
        for (uint256 i = 0; i < tierNames.length; i++) {
            string memory name = tierNames[i];
            TicketTier storage t = tiers[name];
            pendingRefunds[msg.sender] += t.price * purchases[msg.sender][name];
        }
    }

    function claimRefund() external nonReentrant {
        uint256 amt = pendingRefunds[msg.sender];
        require(amt > 0, "No refund");
        pendingRefunds[msg.sender] = 0;
        payable(msg.sender).transfer(amt);
    }

    function payout() public onlyRole(ORGANIZER_ROLE) nonReentrant {
        require(block.timestamp >= eventDate, "Event not done");
        require(!cancelled && !payoutClaimed, "Invalid");
        payoutClaimed = true;
        payable(treasury).transfer(address(this).balance);
    }

    function getTiers() external view returns (string[] memory) {
        return tierNames;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (!cancelled && !payoutClaimed && block.timestamp >= eventDate);
    }

    function performUpkeep(bytes calldata) external override {
        if (!cancelled && !payoutClaimed && block.timestamp >= eventDate) {
            payout();
        }
    }
}
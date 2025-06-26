// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract Ticket1155 is ERC1155, ERC1155Supply, AccessControl, VRFConsumerBaseV2 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    VRFCoordinatorV2Interface public COORDINATOR;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;

    uint256 public nextTokenId;
    mapping(uint256 => uint256) public eventIdForToken;
    mapping(uint256 => string) public uriForToken;
    mapping(uint256 => address) public requestToMinter;
    mapping(uint256 => string) public requestToURI;
    mapping(uint256 => uint256) public requestToEventId;

    event RandomNFTMinted(uint256 requestId, uint256 tokenId, address to);

    constructor(
        address vrfCoordinator,
        uint64 _subId,
        bytes32 _keyHash
    ) ERC1155("") VRFConsumerBaseV2(vrfCoordinator) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subId;
        keyHash = _keyHash;
    }

    function mintWithRandomness(
        address to,
        uint256 eventId,
        string memory uri_
    ) external onlyRole(MINTER_ROLE) returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
        requestToMinter[requestId] = to;
        requestToURI[requestId] = uri_;
        requestToEventId[requestId] = eventId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = nextTokenId++;
        address to = requestToMinter[requestId];
        _mint(to, tokenId, 1, "");
        eventIdForToken[tokenId] = requestToEventId[requestId];
        uriForToken[tokenId] = requestToURI[requestId];
        emit RandomNFTMinted(requestId, tokenId, to);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return uriForToken[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

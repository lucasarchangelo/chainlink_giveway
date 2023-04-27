// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VRFV2Consumer.sol";

contract ChainlinkGiveWays is Ownable, VRFv2Consumer {
    using Counters for Counters.Counter;

    struct ChainlinkEvent {
        string name;
        string giveWayItem;
        uint16 amount;
        Counters.Counter ticketsCount;
        uint256 indexChainLink;
        bool finished;
        address [] winners;
    }

    struct User {
        string name;
        bool hasTicket;
        bool claimed;
    }

    event JoinedToTheEvent(
        string chainlinkEventName,
        address indexed user,
        string name
    );

    Counters.Counter public chainlinkEventId;
    mapping(uint256 => ChainlinkEvent) chainlinkEvent;
    mapping(uint256 => mapping(address => User)) ticketOwners;
    mapping(uint256 => mapping(uint256 => address)) tickets;
    // address[][] tickets;

    constructor(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        address _consumerBase
    )
        VRFv2Consumer(
            _subscriptionId,
            _keyHash,
            _callbackGasLimit,
            _requestConfirmations,
            _consumerBase
        )
    {}

    function createEvent(
        string memory _name,
        string memory _giveWayItem,
        uint16 _amount
    ) external onlyOwner {
        chainlinkEventId.increment();
        uint256 currentChainlinkEvent = chainlinkEventId.current();
        chainlinkEvent[currentChainlinkEvent].name = _name;
        chainlinkEvent[currentChainlinkEvent].giveWayItem = _giveWayItem;
        chainlinkEvent[currentChainlinkEvent].amount = _amount;
    }

    function finishEvent(uint256 _eventId) external onlyOwner {
        require(
            !chainlinkEvent[_eventId].finished,
            "This event is finished already."
        );
        require(
            chainlinkEvent[_eventId].ticketsCount.current() > 0,
            "There's no one on this event"
        );

        chainlinkEvent[_eventId].finished = true;
        chainlinkEvent[_eventId].indexChainLink = requestRandomWords(
            chainlinkEvent[_eventId].amount
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        super.fulfillRandomWords(_requestId, _randomWords);
    }

    function getTheWinners(uint256 _eventId) external onlyOwner {
        uint256 indexChainLink = chainlinkEvent[_eventId].indexChainLink;
        require(s_requests[indexChainLink].fulfilled, "Chainlink didn't answer yet");

    }

    function subscribe(uint256 _eventId, string memory _name) external {
        require(!chainlinkEvent[_eventId].finished, "This event was finished.");
        require(
            !ticketOwners[_eventId][msg.sender].hasTicket,
            "You already have ticket for this event"
        );

        uint256 currentLotteryPosition = chainlinkEvent[_eventId]
            .ticketsCount
            .current();
        chainlinkEvent[_eventId].ticketsCount.increment();

        ticketOwners[_eventId][msg.sender].hasTicket = true;
        ticketOwners[_eventId][msg.sender].name = _name;
        tickets[_eventId][currentLotteryPosition] = msg.sender;

        emit JoinedToTheEvent(chainlinkEvent[_eventId].name, msg.sender, _name);
    }

    // function removeFromCommonStock(uint256 _index) private {
    //     if ((commumCards.length - 1) > _index) {
    //         commumCards[_index] = commumCards[commumCards.length - 1];
    //     }
    //     commumCards.pop();
    // }
}

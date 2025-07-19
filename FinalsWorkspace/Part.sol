// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Part is Ownable {
    // also uses int basis
    enum Condition { MINT, GOOD, FAIR, POOR, BAD  }

    uint256 public partID;
    string public metadata;
    Condition public condition;
    bool public warrantyClaimed;
    address public autoChainAddress;


    constructor(uint256 _partID, string memory _metadata, address _owner) Ownable(_owner) {
        partID = _partID;
        metadata = _metadata;
        condition = Condition.MINT;
        warrantyClaimed = false;
        _transferOwnership(_owner);
        autoChainAddress = msg.sender;
    }

    function updateCondition(Condition _condition) external {
        require(msg.sender == autoChainAddress, "Only owner can update condition");
        condition = _condition;
    }

    function contractTransferOwnership(address newOwner) external {
        require(msg.sender != address(0), "Invalid sender");
        require(msg.sender == autoChainAddress, "Only owner can transfer");
        _transferOwnership(newOwner);
    }

    function claimWarranty() external {
        require(!warrantyClaimed, "Already claimed");
        require(msg.sender == autoChainAddress, "Only owner can claim warranty");
        warrantyClaimed = true;
    }
}
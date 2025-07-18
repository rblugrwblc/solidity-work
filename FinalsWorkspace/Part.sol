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

    constructor(uint256 _partID, string memory _metadata, address _owner) Ownable(_owner) {
        partID = _partID;
        metadata = _metadata;
        condition = Condition.MINT;
        warrantyClaimed = false;
        _transferOwnership(_owner);
    }

    function updateCondition(Condition _condition) external onlyOwner {
        condition = _condition;
    }

    function claimWarranty() external onlyOwner {
        require(!warrantyClaimed, "Already claimed");
        warrantyClaimed = true;
    }
}
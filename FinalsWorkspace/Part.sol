// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract Part {
    enum Condition { BAD, POOR, FAIR, GOOD, MINT }

    uint256 private partID;
    string private carPart;
    string private brand;
    Condition private condition;
    bool private warrantyClaimed;

    address public owner;
    address public autoChainAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyAutoChain() {
        require(msg.sender == autoChainAddress, "Only AutoChainParts can call this");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not part owner");
        _;
    }

    constructor(uint256 _partID, string memory _carPart, string memory _brand, address _initialOwner) {
        require(_initialOwner != address(0), "Invalid owner");
        partID = _partID;
        carPart = _carPart;
        brand = _brand;
        condition = Condition.MINT;
        warrantyClaimed = false;

        owner = _initialOwner;
        autoChainAddress = msg.sender;
    }

    function updateCondition(Condition _condition) external onlyAutoChain {
        condition = _condition;
    }

    function contractTransferOwnership(address newOwner) external onlyAutoChain {
        require(newOwner != address(0), "Cannot transfer to zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function claimWarranty() external onlyAutoChain {
        require(!warrantyClaimed, "Already claimed");
        warrantyClaimed = true;
    }

    function getPartInfo() external view returns (
        uint256 _partID,
        string memory _carPart,
        string memory _brand,
        Condition _condition,
        bool _warrantyClaimed,
        address _currentOwner
    ) {
        return (partID, carPart, brand, condition, warrantyClaimed, owner);
    }
}
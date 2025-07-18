// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Part.sol";

/*
To implement: 
    - Allow it to be applied to real life scenarios 
    - Eg. 
        - fix flow from Manufacturer -> Consumer 
        - where are the payments? 
    - Refine Roles and who is allowed to do things 
    - Can anyone enlist themself for part owner?
    - Do we need multiple files [?]
*/ 

contract AutoChainParts {
    using Counters for Counters.Counter;

    Counters.Counter private _nextPartId; 
    // using int basis for this tho
    enum Role { None, Manufacturer, Distributor, Retailer, Consumer }

    mapping(address => Role) public roles;
    mapping(uint256 => address) public parts;
    mapping(uint256 => address[]) public partHistory;
    uint256 public nextPartId;

    event PartCreated(uint256 partId, address partAddress);
    event Transferred(uint256 partId, address from, address to);

    modifier onlyRole(Role _role) {
        require(roles[msg.sender] == _role, "Wrong role");
        _;
    }

    // Allow anyone to register for role (consider changing this logic)
    function register(Role _role) external {
        require(roles[msg.sender] == Role.None, "Already registered");
        require(_role != Role.None, "Invalid role");
        roles[msg.sender] = _role;
    }

    // Only Manufacturer can make parts
    function createPart(string memory metadata) external onlyRole(Role.Manufacturer) {
        uint256 partId = _nextPartId.current(); 
        Part part = new Part(partId, metadata, msg.sender);
        parts[partId] = address(part);

        partHistory[partId].push(msg.sender);
        emit PartCreated(partId, address(part));
        _nextPartId.increment(); 
    }

    // Transferring part logics 
    function transferPart(uint256 partId, address to) external {
        require(to != address(0), "Invalid to");
        Part part = Part(parts[partId]);
        require(msg.sender == part.owner(), "Not owner");

        Role fromRole = roles[msg.sender];
        Role toRole = roles[to];
        require(_validFlow(fromRole, toRole), "Bad transfer");

        part.transferOwnership(to);
        partHistory[partId].push(to);
        emit Transferred(partId, msg.sender, to);
    }

    // Basically saying M -> D -> R -> C (add more if ever)
    function _validFlow(Role from, Role to) internal pure returns (bool) {
        if (from == Role.Manufacturer && to == Role.Distributor) return true;
        if (from == Role.Distributor && to == Role.Retailer) return true;
        if (from == Role.Retailer && to == Role.Consumer) return true;
        return false;
    }

    function getHistory(uint256 partId) external view returns (address[] memory) {
        return partHistory[partId];
    }

    function claimWarranty(uint256 partId) external {
        Part part = Part(parts[partId]);
        require(msg.sender == part.owner(), "Not owner");
        require(roles[msg.sender] == Role.Consumer, "Not consumer");
        part.claimWarranty();
    }

    function updateCondition(uint256 partId, Part.Condition _condition) external {
        Part part = Part(parts[partId]);
        require(msg.sender == part.owner(), "Not owner");
        part.updateCondition(_condition);
    }
}

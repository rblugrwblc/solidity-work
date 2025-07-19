// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Part.sol";
import "./RoleManager.sol";

contract AutoChainParts {
    using Counters for Counters.Counter;

    Counters.Counter private _nextPartId;
    RoleManager private roleManager;

    mapping(uint256 => address) private parts;
    mapping(uint256 => address[]) private partHistory;
    mapping(uint256 => uint256) private partPrices;
    mapping(uint256 => uint256) private boughtAt;

    uint256 private constant WARRANTY_PERIOD = 1 minutes; // FOR TESTING

    event PartCreated(uint256 partId, address partAddress);
    event Transferred(uint256 partId, address from, address to);

    constructor(address _roleManagerAddress) {
        require(_roleManagerAddress != address(0), "Invalid RoleManager address");
        roleManager = RoleManager(_roleManagerAddress);
    }

    modifier onlyManufacturer() {
        require(roleManager.getRole(msg.sender) == RoleManager.Role.Manufacturer, "Not manufacturer"); 
        _;
    }

    modifier onlyManufacturerOrSeller() {
    RoleManager.Role role = roleManager.getRole(msg.sender);
    require(role == RoleManager.Role.Manufacturer 
        || role == RoleManager.Role.Seller,
        "Not manufacturer or seller"
        );
        _;
    }

    function updatePrice(uint256 partId, uint256 _newPrice) external onlyManufacturerOrSeller  {
        Part part = Part(parts[partId]);
        require(msg.sender == part.owner(), "Not owner"); 

        part.updatePartPrice(_newPrice); 

    }

    function createPart(string memory partName, uint256 partPrice) external onlyManufacturer() {
        uint256 partId = _nextPartId.current();

        // Default Price is set to 0 
        Part part = new Part(0, partId, partName, roleManager.getManufacturerBrand(msg.sender), msg.sender);
        parts[partId] = address(part);

        partPrices[partId] = partPrice * 1 ether;
        partHistory[partId].push(msg.sender);

        emit PartCreated(partId, address(part));
        _nextPartId.increment();
    }

    function transferPart(uint256 partId, address to) external {
        require(to != address(0), "Invalid recipient");
        Part part = Part(parts[partId]);
        require(msg.sender == part.owner(), "Not owner");

        RoleManager.Role fromRole = roleManager.getRole(msg.sender);
        RoleManager.Role toRole = roleManager.getRole(to); 

        require(_validFlow(fromRole, toRole), "Bad transfer");

        if (toRole == RoleManager.Role.Buyer) {
            boughtAt[partId] = block.timestamp;
        }

        part.contractTransferOwnership(to);
        partHistory[partId].push(to);
        emit Transferred(partId, msg.sender, to);
    }

    function buyPart(uint256 partID) external payable {
        address buyer = msg.sender;
        Part part = Part(parts[partID]);
        address seller = part.owner();
        uint256 price = partPrices[partID];

        require(buyer != address(0), "Invalid buyer");
        require(buyer != seller, "Already owner");
        require(msg.value >= price, "Insufficient funds");
        require(_validFlow(roleManager.getRole(seller), roleManager.getRole(buyer)), "Transfer not allowed");

        payable(seller).transfer(price);

        if (msg.value > price) {
            payable(buyer).transfer(msg.value - price);
        }

        part.contractTransferOwnership(buyer);
        partHistory[partID].push(buyer);
        boughtAt[partID] = block.timestamp;

        emit Transferred(partID, seller, buyer);
    }

    function _validFlow(RoleManager.Role from, RoleManager.Role to) internal pure returns (bool) {
        if (from == RoleManager.Role.Manufacturer && to == RoleManager.Role.Seller) return true;
        if ((from == RoleManager.Role.Seller && to == RoleManager.Role.Buyer) 
            || (from == RoleManager.Role.Buyer && to == RoleManager.Role.Seller)) return true;
        return false;
    }

    function claimWarranty(uint256 partId) external {
        Part part = Part(parts[partId]);
        require(msg.sender == part.owner(), "Not owner");
        require(roleManager.getRole(msg.sender) == RoleManager.Role.Buyer, "Not a buyer");
        require(boughtAt[partId] != 0, "Not purchased");
        require(block.timestamp <= boughtAt[partId] + WARRANTY_PERIOD, "Warranty expired");

        part.claimWarranty();
    }

    function updateCondition(uint256 partId, Part.Condition _condition) external {
        Part part = Part(parts[partId]);
        require(msg.sender == part.owner(), "Not owner");
        part.updateCondition(_condition);
    }

    function viewPartDetails(uint256 partId) external view returns (
        string memory carPart, 
        string memory brand, 
        Part.Condition condition, 
        address currentOwner 
        ) {
        
        Part part = Part(parts[partId]);
        return (
            part.getCarPart(),
            part.getBrand(),
            part.getCondition(),
            part.owner()
        );
    }

    function getPartTransferRecord(uint256 partId, uint256 transactionNumber) external view returns (
        address from, 
        address to, 
        uint256 timestamp 
    ) {
        Part part = Part(parts[partId]);
        return part.getTransferRecord(transactionNumber);
    }

}

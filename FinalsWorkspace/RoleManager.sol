// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract RoleManager {
    enum Role { None, Manufacturer, Seller, Buyer }

    struct User {
        Role role;
        address userAddress;
    }

    struct ManufacturerProfile {
        string brandName;
        string location;
    }

    struct SellerProfile {
        string shopName;
        string locaton;
    }

    struct BuyerProfile {
        string name;
        string contactInfo;
    }

    mapping(address => User) private users;
    mapping(address => ManufacturerProfile) private manufacturers;
    mapping(address => SellerProfile) private sellers;
    mapping(address => BuyerProfile) private buyers;


    modifier notRegistered() {
        require(users[msg.sender].role == Role.None, "Already registered");
        _;
    }

    function registerManufacturer(string memory brandName, string memory location) external notRegistered {
        users[msg.sender] = User(Role.Manufacturer, msg.sender);
        manufacturers[msg.sender] = ManufacturerProfile(brandName, location);
    }

    function registerSeller(string memory shopName, string memory location) external notRegistered {
        users[msg.sender] = User(Role.Seller, msg.sender);
        sellers[msg.sender] = SellerProfile(shopName, location);
    }

    function registerBuyer(string memory name, string memory contactInfo) external notRegistered {
        users[msg.sender] = User(Role.Buyer, msg.sender);
        buyers[msg.sender] = BuyerProfile(name, contactInfo);
    }

    function getManufacturerBrand(address user) external view returns (string memory brand) {
        require(users[user].role == Role.Manufacturer, "Not a manufacturer"); 
        return manufacturers[user].brandName; 
    }

    function getBuyerInfo(address user) external view returns ( string memory contactInfo) {
        require(users[user].role == Role.Buyer, "Not a buyer");
        return buyers[user].contactInfo;
    }

    function getUser(address user) external view returns (User memory) {
        return users[user];
    }

    function getRole(address user) external view returns (Role) {
        return users[user].role;
    }
 
}

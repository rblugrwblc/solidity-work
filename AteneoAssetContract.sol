// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/*
INSTRUCTIONS FOR DEPLOYMENT (FROM ROBIN CACHO)
1. Deploy AteneoLendingContract
2. Call ListItem(Name, BorrowPrice) from owner account
3. Call Borrow(item id) from borrower account 
4. Call ListedAssets(item id) from AteneoLendingContract
5. Deploy an AssetContract at the address of currentContract (THIS IS IMPORTANT) 
6. Return Book
*/ 

/// @notice Structure representing an asset available for lending
struct Asset {
    address owner;
    string name;
    uint rental_fee;
    bool borrowed;
    address currentContract;
}

contract AteneoLendingContract {
    // TO ADD: Set the penalty fee for returning an asset late
    // TO ADD: Set the security deposit for all borrowers 
    uint public constant PENALTY_FEE = 2000000; 
    uint public constant SECURITY_DEPOSIT = 1000000; 
    
    mapping(address => bool) public flags; // Mapping of flagged users
    mapping(address => bool) private borrowers; // Mapping of borrowers and borrowing status
    Asset[] public listedAssets; // Array of assets for borrowing

    /// @notice Modifier that checks if user is flagged
    modifier flagged() {
        // TO ADD: Modifier to check if user is flagged, 
        // else revert with an error message saying that user is not flagged
        require(flags[msg.sender], "This user is NOT currently flagged!"); 
        _;
    }

    /// @notice Modifier that checks if user is not flagged
    modifier notFlagged() {
        // TO ADD: Modifier to check if user is not flagged, 
        // else revert with an error message for paying penalty
        require(
            !flags[msg.sender], 
            "This user is currently flagged!"
        );
        _;
    }

    /// @notice Modifier that checks if user is not flagged
    modifier notBorrowing() {
        // TO ADD: Modifier to check if user is not currently borrowing an asset
        require(
            !borrowers[msg.sender], 
            "This user is currently borrowing an asset!"
        );
        _;
    }

    // Event Logging 
    event AssetListed(uint itemId, string name, uint rentalFee);
    event AssetBorrowed(uint itemId, address borrower, address contractAddress);

    /// @notice List a new asset for lending
    /// @param _name The name of the asset
    /// @param _rental_fee The rental fee for borrowing the asset
    function listItem(string memory _name, uint _rental_fee) external {
        // TO ADD: Add asset to the list of available assets
        Asset memory newAsset = Asset({
            owner: msg.sender,
            name: _name,
            rental_fee: _rental_fee,
            borrowed: false,
            currentContract: address(0)
        }); 
        listedAssets.push(newAsset);
        emit AssetListed(listedAssets.length - 1, _name, _rental_fee);
    }

    /// @notice Borrow an asset by ID, paying rental and deposit fees
    /// @param _itemId The index of the asset in the list
    function borrow(uint _itemId) external payable notBorrowing notFlagged {
        // TO ADD: Check if _itemId is valid i.e. determine if out of bounds 
        
        require(
            _itemId < listedAssets.length, 
            "This item does not exist!"
        );

        Asset storage asset = listedAssets[_itemId];
       
        // TO ADD: Check if asset is already borrowed
        require(
            !asset.borrowed, 
            "Asset is already borrowed!"); 

        // TO ADD: Check if the payment is correct
        require(
            msg.value == SECURITY_DEPOSIT + asset.rental_fee, 
            "This is not the correct payment!"
        );

        // TO ADD: Handle borrowing action, transfer deposit and rental fees, 
        // and update borrower and item status
        AssetContract assetContract = new AssetContract(
            address(this),
            asset.owner,
            msg.sender,
            _itemId
        );

        asset.borrowed = true;
        asset.currentContract = address(assetContract);
        borrowers[msg.sender] = true;

        emit AssetBorrowed(_itemId, msg.sender, address(assetContract));
    }

    /// @notice Mark an asset as returned (can only be called by the AssetContract)
    /// @param _itemId The index of the asset in the list
    function markReturned(uint _itemId, address _borrower) external {
        require(_itemId < listedAssets.length, "Invalid item ID");
        Asset storage asset = listedAssets[_itemId];

        // TO ADD: Validate if caller is AssetContract
        require(
            msg.sender == asset.currentContract, 
            "Caller is not the Asset Contract"
        );

        // TO ADD: Validate if asset is borrowed
        require(
            asset.borrowed, 
            "This Asset is not currently borrowed"
        );

        // TO ADD: Update borrower and item status
        borrowers[_borrower] = false;
        asset.borrowed = false;
        asset.currentContract = address(0);
    }

    /// @notice Flag a borrower who returned an asset late (can only be called by the AssetContract)
    /// @param _borrower The address of the borrower to be flagged
    /// @param _itemId The index of the borrowed asset
    function flag(address _borrower, uint _itemId) external {
        // TO ADD: Validate _itemId
        require (_itemId < listedAssets.length, "This item does not exist"); 

        // TO ADD: Validate if caller is AssetContract
        Asset storage asset = listedAssets[_itemId]; 
        require(msg.sender == asset.currentContract, "Only the Asset Contract can call this!"); 

        // TO ADD: Update borrower status
        flags[_borrower] = true; 
        borrowers[_borrower] = false; 
    }

    /// @notice Pay the penalty fee to remove the flagged status
    function payPenalty() external payable flagged {
        // TO ADD: Check penalty payment amount and update borrower status
        require(
            msg.value == PENALTY_FEE, 
            "The entered ammount to pay the penalty is not correct!"
        ); 
        flags[msg.sender] = false; 
    }

    /// @notice Retrieve the full list of listed assets
    /// @return An array of all listed assets
    function getListedAssets() public view returns (Asset[] memory) {
        // TO ADD: Return the array of listed assets
        
        // this is a quite literal approach lol
        return listedAssets; 
    }
}

contract AssetContract {
    // REVERT BACK TO PRIVATE
    address public parent;
    address public owner;
    address public borrower;
    uint public itemId;
    uint public deadline;
    bool public returned;
    uint private duration = 5 seconds; // Set to 30 seconds only for testing purposes

    /// @notice Allow this contract to receive ether
    // TO ADD: fallback function to receive Ether transfers
    receive() external payable {}

    /// @notice Constructor sets initial state and deadline
    /// @param _parent The address of the AteneoLendingContract
    /// @param _owner The original owner of the asset
    /// @param _borrower The borrower of the asset
    /// @param _itemId The index of the borrowed asset
    constructor(address _parent, address _owner, address _borrower, uint _itemId) payable {
        // Define init state
        parent = _parent; 
        owner = _owner; 
        borrower = _borrower; 
        itemId = _itemId; 
        
        // Set the deadline
        deadline = block.timestamp + duration; 
    }

    /// @notice Called by borrower to return the item, returns the deposit fee, and triggers penalty if overdue
    function returnItem() external {
        // TO ADD: Verify the borrower
        require(msg.sender == borrower, "You are not the borrower!"); 

        // TO ADD: Verify if the asset has already been returned
        require(!returned, "Item already returned!"); 
        returned = true; 

        // TO ADD: Handle return actions, update the return status, 
        // check return timestamp, and handle penalties if overdue
        bool isLate = block.timestamp > deadline; 
        
        uint deposit = AteneoLendingContract(parent).SECURITY_DEPOSIT();
        
        if (!isLate) {
            payable(borrower).transfer(deposit);
            AteneoLendingContract(parent).markReturned(itemId, borrower);
        } 
        else {
            AteneoLendingContract(parent).flag(borrower, itemId); 
        }

    }
}
     


// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title RizalLib
 * @dev A library management system smart contract that allows a librarian to add students,
 * and lets students borrow and return books, with penalties for late returns.
 */
contract RizalLib {
    address internal librarian; 

    // Forgive me for the bad variable names 
    enum HOLDORDER { HAS, NONE }
    enum HASBOOK { HAS, NONE } 

    /*
     * @dev Structure representing a student
     */
    struct Student {
        uint idNumber; 
        uint bookNumber; 
        HOLDORDER Hold; 
        HASBOOK Book;  
    }

    /*
     * @dev Modifier to ensure only students can access a function
     */
    modifier isStudent() {
        require(
            msg.sender != librarian, 
            "You are the librarian!"
        ); 
        _; 
    }

    /*
     * @dev Modifier to ensure only the librarian can access a function
     */
    modifier isLibrarian() {
        require(
            msg.sender == librarian,
            "You are NOT the librarian!"
        );  
        _;
    }

    /*
     * @dev Modifier to check if student is allowed to borrow a book
     */
    modifier isAllowed() {
        // Check if the student exists in system; has no book & penalty
        require( 
            students[msg.sender].idNumber != 0
                && students[msg.sender].Book == HASBOOK.NONE
                && students[msg.sender].Hold == HOLDORDER.NONE, 
            "You are not allowed to borrow a book!"
        );
        _; 
    } 

    /*
     * @dev Modifier to check if student has a hold order (penalty)
     */
    modifier hasHoldOrder() {
        require(
            students[msg.sender].Hold == HOLDORDER.HAS, 
            "You have no balance to pay"
        ); 
        _; 
    } 

    /*
     * @dev Modifier to check if enough Wei was sent to pay the penalty
     */
    modifier enoughPayment() {
        require(
            msg.value >= penaltyAmount,
            "Insufficient payment"
        );
        _; 
    }
    
    // Mappings to store student records and borrowed timestamps
    mapping(address => Student) public students; 
    mapping(address => uint) public borrowedAt; 
    mapping(uint => bool) public borrowedBook; //check if book is borrowed or not

    // Configuration variables 
    uint public nextId = 10000001; // another approach is hash address 
    uint public deadline = 14 days;
    uint public penaltyAmount = 50000; // Default currency is Wei

    /*
     * @dev Constructor sets the contract deployer as the librarian
     */
    constructor() {
        librarian = msg.sender; 
    }

    /**
     * @dev Add a new student, generates their student id
     * @param _student The address of the student to add
     */ 
    function addStudent(address _student) public isLibrarian {
        require (
            _student != librarian,
            "Librarian cannot be student!"
        ); 
        
        // This is done in the code for ease of checking 
        require (
            students[_student].idNumber == 0, 
            "You are already a student!"
        );

        // Create a new student
        students[_student] = Student({
            idNumber: nextId,
            bookNumber: 0, // Set to 0 to denote no book
            Hold: HOLDORDER.NONE,
            Book: HASBOOK.NONE
        }); 

        // Make sure to increment next studentID number. 
        nextId++; 
    }

    /*
     * @dev Attempt to borrow a book
     * @param _bookNumber The book number to be borrowed
     */ 
    function borrow(uint _bookNumber) public isAllowed {
        require (
            _bookNumber != 0, 
            "This book does not exist!"
        );
        require (
            !borrowedBook[_bookNumber], //not currently borrowed
            "This book is unavailable"
        );
        students[msg.sender].bookNumber = _bookNumber; 
        students[msg.sender].Book = HASBOOK.HAS;
        borrowedAt[msg.sender] = block.timestamp;
        borrowedBook[_bookNumber] = true; //if borrowed then true
        
    }

    /**
     * @dev Return a borrowed book; applies penalty if returned late
     * NOTE: It is changed to returnBook() to prevent clashing, LMK IF THIS IS LEGAL cause proj specs are return()
     */
    function returnBook() public isStudent {
        require(students[msg.sender].Book == HASBOOK.HAS, "You have no book to return");

        uint borrowedTime = borrowedAt[msg.sender];
        uint bookNum = students[msg.sender].bookNumber;
        require(borrowedTime != 0, "Borrow record not found");
        

        if (block.timestamp > borrowedTime + deadline) {
            students[msg.sender].Hold = HOLDORDER.HAS; 
        }

        // Reset student book status
        students[msg.sender].Book = HASBOOK.NONE;
        students[msg.sender].bookNumber = 0;
        borrowedAt[msg.sender] = 0;
        borrowedBook[bookNum] = false; //if returned then borrowed book is false

    }

    /**
     * @dev Pay the penalty balance; clears hold order
     */
    function payBalance() public payable isStudent hasHoldOrder enoughPayment {
        students[msg.sender].Hold = HOLDORDER.NONE;
    }
}


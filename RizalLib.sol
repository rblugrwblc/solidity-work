// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title RizalLib
 * @dev A library management system smart contract that allows a librarian to add students,
 * and lets students borrow and return books, with penalties for late returns.
 */
contract RizalLib {
    // Contract deployer is the librarian
    address private immutable librarian;

    // enums to track student status
    enum HoldStatus { NONE, HAS }
    enum BookStatus { NONE, HAS }

    /**
     * @dev Represents a student in the system
     */
    struct Student {
        uint256 idNumber;
        uint256 bookNumber;
        HoldStatus hold;
        BookStatus book;
    }

    // defines mapping, variables, event names and modifiers needed
    mapping(address => Student) private students;
    mapping(address => uint256) private borrowedAt;
    mapping(uint256 => bool) private borrowedBook;

    uint256 private nextId = 10000001;
    uint256 private constant DEADLINE = 14 days;
    uint256 private constant PENALTY_AMOUNT = 50000; // in Wei

    event StudentAdded(address indexed student, uint256 idNumber, HoldStatus hold, BookStatus book);
    event BookBorrowed(address indexed student, uint256 bookNumber, BookStatus book);
    event BookReturned(address indexed student, uint256 bookNumber, BookStatus book);
    event BalancePaid(address indexed student, HoldStatus hold);

    /*
     * @dev Modifier to ensure only the librarian can access a function
     */
    modifier onlyLibrarian() {
        require(
            msg.sender == librarian, 
            "You are NOT the librarian!"
        );
        _;
    }

    /*
     * @dev Modifier to ensure only a student can access a function
     */

    modifier onlyStudent() {
        require(
            msg.sender != librarian, 
            "You are the librarian!"
        );
        _;
    }

    /*
     * @dev Modifier to check if student is allowed to borrow a book
     */

    modifier canBorrow() {
        require(
            students[msg.sender].idNumber != 0 
                && students[msg.sender].book == BookStatus.NONE 
                && students[msg.sender].hold == HoldStatus.NONE,
            "You are not allowed to borrow a book!"
        );
        _;
    }

    /*
     * @dev Modifier to check if student has a hold order 
     */

    modifier hasHoldOrder() {
        require(
            students[msg.sender].hold == HoldStatus.HAS, 
            "You have no balance to pay"
        );
        _;
    }

    /*
     * @dev Modifier to check if enough Wei was sent to pay the penalty
     */ 

    modifier sufficientPayment() {
        require(
            msg.value >= PENALTY_AMOUNT, 
            "Insufficient payment"
        );
        _;
    }

    /*
     * @dev Sets the deployer as librarian
     */
    constructor() {
        librarian = msg.sender;
    }

    /*
     * @dev Adds a new student with a unique ID
     * @param _student The address of the student to add
     */
    function addStudent(address _student) external onlyLibrarian {
        require(_student != librarian, "Librarian cannot be a student!");
        require(students[_student].idNumber == 0, "You are already a student!");

        students[_student] = Student({
            idNumber: nextId,
            bookNumber: 0,
            hold: HoldStatus.NONE,
            book: BookStatus.NONE
        });

        emit StudentAdded(_student, nextId, HoldStatus.NONE, BookStatus.NONE);
        nextId++;
    }

    /*
     * @dev Allows a student to borrow a book if eligible
     * @param _bookNumber The number of the book to borrow
     */
    function borrow(uint256 _bookNumber) external onlyStudent canBorrow {
        require(_bookNumber != 0, "This book does not exist!");
        require(!borrowedBook[_bookNumber], "This book is unavailable");

        students[msg.sender].bookNumber = _bookNumber;
        students[msg.sender].book = BookStatus.HAS;
        borrowedAt[msg.sender] = block.timestamp;
        borrowedBook[_bookNumber] = true;

        emit BookBorrowed(msg.sender, _bookNumber, BookStatus.HAS);
    }

    /*
     * @dev Returns the borrowed book; applies penalty if overdue
     */
    function returnBook() external onlyStudent {
        require(students[msg.sender].book == BookStatus.HAS, "You have no book to return");

        uint256 borrowTime = borrowedAt[msg.sender];
        uint256 bookNum = students[msg.sender].bookNumber;

        require(borrowTime != 0, "Borrow record not found");

        if (block.timestamp > borrowTime + DEADLINE) {
            students[msg.sender].hold = HoldStatus.HAS;
        }

        students[msg.sender].book = BookStatus.NONE;
        students[msg.sender].bookNumber = 0;
        borrowedAt[msg.sender] = 0;
        borrowedBook[bookNum] = false;

        emit BookReturned(msg.sender, bookNum, BookStatus.NONE);
    }

    /*
     * @dev Allows a student to pay penalty to clear their hold status
     */
    function payBalance() external payable onlyStudent hasHoldOrder sufficientPayment {
        students[msg.sender].hold = HoldStatus.NONE;
        emit BalancePaid(msg.sender, HoldStatus.NONE);
    }
}

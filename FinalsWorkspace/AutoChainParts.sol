// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17; 

//DOCUMENTAITON FOR COUNTERS:  https://docs.openzeppelin.com/contracts/5.x/ 
// Also used this as reference: https://forum.openzeppelin.com/t/setup-counter-to-start-at-1/13457
import "@openzeppelin/contracts/utils/Counters.sol"; 

/*
To Do List: 
    - Implement Counter 
    - Implement Roles 
        Manufacturer
        - Implement Role's Function (refer to specs)
    - Repeat Cycle for 2 Including their possible functions
    - Implement Transfer Function 
    - Consider refactoring Code 
*/

contract AutoChainParts {
    using Counters for Counters.Counter; 

    // implement part counting system 
    Counters.Counter private _nextPartId;

    enum Condition{ MINT, GOOD, FAIR, POOR, BAD }

    // structures to take note of 
    struct Part {
        uint256 partID; 
        Condition condition; 
        string partType; 
        string manufacturer;  
        uint productionDate;
        string authenticityHash; // tf is an authenticityHash 
        string brand;  
    }

    // not sure if the state modifier is right for this
    mapping(uint256 => Part) public parts; 

    constructor() {
    }

    // To implement, require isManufcaturer 
    function createPart(string memory _partType, string memory metaDataHash) public { 
        // Logic for handling part creation 
        uint256 partId = _nextPartId.current();
        _nextPartId.increment(); 

        // Generate a new part based on the thing 
        parts[partId] = Part({
            partID: partId,
            condition: Condition.MINT,
            partType: _partType, 
            // REPLACE WHEN ROLES
            manufacturer: "BMW",  
            productionDate: block.timestamp,
            // ???? WHAT IS AUTHENTICITY HASH PLS
            authenticityHash: metaDataHash,
            // REPLACE WHEN ROLES 
            brand: "BMW"
        }); 
    }

}

/// For transfering later

    struct Transfer {
        uint256 transferID;
        uint256 partID;
        address from;
        address to;
        uint256 transferDate;
        string Status; 
        string transferHash;
    }

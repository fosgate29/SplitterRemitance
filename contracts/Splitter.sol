pragma solidity ^0.4.11;


/**
 * @title Splitter contract. 
 * Consensys Dev Academy exercise - Small projects - Module 4
 * 
 */
contract Splitter {
    
    //states
    address public owner;
    
    event LogTransferred(address indexed receiver, uint amount);
    event LogSplitterCreated(address indexed msgSender, address indexed user1, address indexed user2, 
                              uint half , uint  remainder);
    
    mapping(address => uint) balances;
    
    //Constructor
    function Splitter() {
        owner = msg.sender;
    }
    
    //split the value received between two users and update their balance
    function split(address address1, address address2) payable public returns(bool success) {
        //checking address not equal to zero to make sure balances mapping has no address equal to zero
        if(address1 == 0 || address2 == 0 ) revert();
        
        balances[address1] +=  msg.value / 2;
        balances[address2] +=  msg.value / 2;
        
        //msg sender gets 1 wei if it is an odd number
        if(msg.value % 2 == 1){
            balances[msg.sender] += 1;
        }
        
        LogSplitterCreated(msg.sender, address1, address2,  msg.value / 2 , msg.value % 2);
        
        return true;
    }
   
    // user collect his money 
    function withdrawFunds() public returns(bool success) { 
        uint amountToTransfer = balances[msg.sender];
        
        require(amountToTransfer>0);  //thanks @nikhilwins
        
        balances[ msg.sender] = 0;
        msg.sender.transfer(amountToTransfer);
            
        LogTransferred(msg.sender, amountToTransfer);
        
        return true;
    }
    
    //It will kill the contract and return all remain funds to the 
    //contract owner
    function killMe() public returns ( bool success) {
        require(msg.sender == owner);
        
        uint amount = this.balance;
        
        suicide(owner);
        
        LogTransferred(msg.sender, amount);
        
        return true;
    }

    //fallback is not payable, so contract can´t receive funds
    function () {
    }
}

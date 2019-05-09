pragma solidity ^0.5.0;


/**
 * @title Splitter contract. 
 * Consensys Dev Academy exercise - Small projects - Module 4
 * 
 */
contract Splitter {
    
    //states
    address payable public owner;
    
    event LogTransferred(address indexed receiver, uint amount);
    event LogSplitterCreated(address indexed msgSender, address indexed user1, address indexed user2, 
                              uint half , uint  remainder);
    
    mapping(address => uint) public balances;
    
    //Constructor
    constructor() public {
        owner = msg.sender;
    }
    
    //split the value received between two users and update their balance
    function split(address address1, address address2) payable public returns(bool success) {
        //checking address not equal to zero to make sure balances mapping has no address equal to zero
        require(address1 != address(0) && address2 != address(0) , 'Invalid addres for address1 or address2');
        
        balances[address1] +=  msg.value / 2;
        balances[address2] +=  msg.value / 2;
        
        //msg sender gets 1 wei if it is an odd number
        if(msg.value % 2 == 1){
            balances[msg.sender] += 1;
        }
        
        emit LogSplitterCreated(msg.sender, address1, address2,  msg.value / 2 , msg.value % 2);
        
        return true;
    }
   
    // user collect his money 
    function withdrawFunds() public returns(bool success) { 
        uint amountToTransfer = balances[msg.sender];
        
        require(amountToTransfer>0, 'Amount to transfer must be greater than zero');  //thanks @nikhilwins
        
        balances[ msg.sender] = 0;
        msg.sender.transfer(amountToTransfer);
            
        emit LogTransferred(msg.sender, amountToTransfer);
        
        return true;
    }
    
    //It will kill the contract and return all remain funds to the 
    //contract owner
    function killMe() public returns ( bool success) {
        require(msg.sender == owner, 'Sender must be the owner');
        
        uint amount = address(this).balance;
        
        selfdestruct(owner);
        
        emit LogTransferred(msg.sender, amount);
        
        return true;
    }
}

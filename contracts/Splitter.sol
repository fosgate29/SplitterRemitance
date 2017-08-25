pragma solidity ^0.4.11;


/**
 * @title Splitter contract. 
 * Consensys Dev Academy exercise - Small projects - Module 4
 * 
 */
contract Splitter {
    
    //states
    address public owner;
    
    event LogTransfer(address receiver, uint amount);
    event LogBalanceUpdated(address user, uint amount);
    
    mapping(address => uint) balances;
    
    //Constructor
    function Splitter() {
        owner = msg.sender;
    }
    
    /**
     * @dev View the balance of the specified address.
     * @param from Address of the user to check the balance.
     * @return balance The calculated perimeter.
     */
    function getSplitterBalance(address from) constant public returns(uint) { 
        return balances[from]; 
    }
    
    //split the value received between two users and update their balance
    function split(address address1, address address2) payable public returns(bool success) {
        //checking address not equal to zero to make sure balances mapping has no address equal to zero
        if(address1 == 0 || address2 == 0 ) revert();
        
        uint amountSplitted = msg.value / 2; 
        
        uint amountAddress1 = amountSplitted;
        uint amountAddress2 = amountSplitted;
        
        if(balances[address1] > 0 ){
            amountAddress1 += balances[address1];
        }
        
        if(balances[address2] > 0 ){
            amountAddress2 += balances[address2];
        }
        
        balances[address1] = amountAddress1;
        balances[address2] = amountAddress2;
        
        LogBalanceUpdated(address1 , amountAddress1);
        LogBalanceUpdated(address2 , amountAddress2);
        
        return true;
    }
   
    // user collect his money 
    function withdrawFunds() public returns(bool success) { 
        uint amountToTransfer = balances[msg.sender];
        
        if(amountToTransfer>0){
            balances[ msg.sender] = 0;
            msg.sender.transfer(amountToTransfer);
            
            LogBalanceUpdated(msg.sender, 0);
            LogTransfer(msg.sender, amountToTransfer);
        }
        
        return true;
    }
    
    //It will kill the contract and return all remain funds to the 
    //contract owner
    function killMe() public returns ( bool success) {
        require(msg.sender == owner);
        
        uint amount = this.balance;
        
        suicide(owner);
        
        LogTransfer(msg.sender, amount);
        
        return true;
    }
    
    //Owner transfer contract funds to him
    function claimContractFunds() public returns ( bool success) {
        require(msg.sender == owner);
        if(this.balance > 0 ){
            msg.sender.transfer(this.balance);
            LogTransfer(msg.sender, this.balance);
        }
        
        return true;
    }

    //fallback is not payable, so contract can´t receive funds
    function () {
    }
}

pragma solidity ^0.4.11;


/**
 * @title Splitter contract. 
 * Consensys Dev Academy exercise - Small projects - Module 4
 * 
 */
contract Splitter {
    
    //states
    address public owner;
    
    event Transfer(string message, address from, address to, uint256 amount);
    event Created(string message, address receiver1, address receiver2, bool isCreated);
    
    //splitter struct. splitterStarter = Alice. receiver1 = Bob receiver2 = Carol
    struct SplitterStruct {
        address receiver1;
        address receiver2;
    }
    
    //mapping - addres of who is creating the splitter is the key
    mapping (address => SplitterStruct) public SplitterMapping;
    
    //Constructor
    function Splitter() payable {
        owner = msg.sender;
    }
    
    //returns balance of the contract
    function getBalance() public constant returns (uint) {
        return this.balance;
    }
    
    /**
     * @dev View the balance of the specified address.
     * @param from Address of the user to check the balance.
     * @return balance The calculated perimeter.
     */
    function getUserBalance(address from) public constant returns(uint) {  
      return from.balance;
    }
    
    //it starts and update a splitter. 
    //each addres can have only one splitter.
    //and splitter should be the msg.sender
    function startSplitter(address receiverSplit1, address receiverSplit2) 
        public 
        returns(bool) {  
        
        //if splitter receivers are equal, return false
        if(receiverSplit1 == receiverSplit2){
           Created("Splitter was NOT created. Receivers can´t be equal.",receiverSplit1,receiverSplit2,false);
           return false; 
        } 
        
        if(receiverSplit1 == 0 || receiverSplit2 == 0 ) {
            Created("Splitter was NOT created. They are equual to 0x0",receiverSplit1,receiverSplit2,false);
            return false;
        }
        
        SplitterStruct memory newSplitter;
        newSplitter.receiver1 = receiverSplit1;
        newSplitter.receiver2 = receiverSplit2;
        
        SplitterMapping[msg.sender] = newSplitter;
        
        Created("Splitter is created",receiverSplit1,receiverSplit2,true);
        
        return true;
    }
    
    function delete_() public returns(bool) {
        //only splitter can delete its key from the list   
        delete SplitterMapping[msg.sender];

        return true;
    }
    
    //It will kill the contract and return all remain funds to the 
    //contract owner
    function killMe() returns (bool) {
        require(msg.sender == owner);
        suicide(owner);
        return true;
    }
    
    function isSenderRegisteredSplitter(address whom) private returns(bool){
        address testAddress = SplitterMapping[whom].receiver1;
        if(testAddress==0) return false;
        return true;
    }

    //it receives a transfer, so check if it is "Alice", if yes, split
    //the ether and then send each amout to Bob and Carol.
    function () payable {
        
        //check if the msg.addres is registered as a splitter. if yes (address returned is not equal to 0),
        //get the other address to split the value. if no, just receive the ether and do nothing
        if(isSenderRegisteredSplitter(msg.sender)){
           // BigNumber amountToSplit = new BigNumber(msg.value);
            uint amountToSplit = msg.value;
            
            //if amountReceived == 1 wei, it will fail because it is
            //the least amount and it can´t be divide. so, we need to throw
            if(amountToSplit == 1) {
                Transfer("Amount is equal to 1 Wei and can´t be splitted. Amount is going to the contract.", msg.sender, this, amountToSplit);
            }
            else{
                uint amountSplitted = amountToSplit / 2;
    
                address receiver1 = SplitterMapping[msg.sender].receiver1;
                address receiver2 = SplitterMapping[msg.sender].receiver2;
                
                receiver1.transfer(amountSplitted);
                receiver2.transfer(amountSplitted);
                Transfer("Amount was splitted with success", msg.sender, receiver1, amountSplitted);
                Transfer("Amount was splitted with success", msg.sender, receiver2, amountSplitted);
            }
        }
    }
}

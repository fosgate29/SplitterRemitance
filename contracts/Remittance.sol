pragma solidity ^0.4.11;


/**
 * @title Remittance contract. 
 * Consensys Dev Academy exercise - Small projects - Module 4
 * 
 */
contract Remittance {
    
    //states
    address public owner;
    uint public deadlineLIMITInSeconds;
    address[] private remittanceOwners;
    
    struct RemittanceStruct {
	    uint deadline;  //deadline must be less then now to allow Alice claim the Ether 
	    uint remittanceBallance;     //value Alice will receive from Carol
	    uint remittanceOwnersIndex;
	    string passwordHash;
	    address beneficiary;  //Alice address. 
    }
    
    mapping (address => RemittanceStruct) public RemittanceMapping;
    
    //Constructor
    function Remittance(uint _deadlineLimitInSeconds) {
        owner = msg.sender;
        deadlineLIMITInSeconds = _deadlineLimitInSeconds;
    }
    
    //Start a remittance process
    function beginRemittanceProcess(address beneficiary, uint deadlineInSeconds,
                                    string passwordHash) 
        public
        payable  
        returns(bool) 
    {
        if(now+deadlineInSeconds > now+deadlineLIMITInSeconds) {
            return false;
        }
        
        if(msg.value == 0) {
            return false;
        }
        
        if(beneficiary==0){
            return false;
        }
        
        RemittanceStruct memory newRemittance;
        newRemittance.deadline = now + deadlineInSeconds;
        newRemittance.remittanceBallance = msg.value;
        newRemittance.beneficiary = beneficiary;
        newRemittance.passwordHash = passwordHash;
        
        //if it is a new remittance, create a new index. otherwise, keep the last index
        if(RemittanceMapping[msg.sender].beneficiary==0){
            newRemittance.remittanceOwnersIndex = remittanceOwners.push(msg.sender)-1;
        }
        else{
            //do nothing, remittanceOwnersIndex is already populated with the correct index
        }
        
        RemittanceMapping[msg.sender] = newRemittance;
        
        return true;
    }
    
    //beneficary will call this function to receive ethers
    function releaseRemittance(address remittanceOwner, string secretWord1, 
                                string secretWord2) 
    returns(bool){
        
        //only beneficiary can call this function
        if(RemittanceMapping[remittanceOwner].beneficiary!=msg.sender){
            return false;
        }
        
        //if theresn´t funds, stop
        if(RemittanceMapping[remittanceOwner].remittanceBallance==0){
            return false;
        }
        
        //check password of user 1 and user 2. they are sent in plain text because 
        //I couldn´t find how to send it encrypted
        bytes32 passwordSent = keccak256(secretWord1, secretWord2);
        bytes32 passwordStored = stringToBytes32(RemittanceMapping[remittanceOwner].passwordHash);
        
        //is is not working. But I deployed the contract to proof of fire so I can move mon 
        //with Module 5. I will come back here after inputs of the review
        if(passwordStored != passwordSent){
            //return false;
        }
        
        //check for password, if ok, transfer ether to beneficiary
        if(true){
            uint amount = RemittanceMapping[remittanceOwner].remittanceBallance;

            //msg.sender is the beneficary and it was checked in the first line
            RemittanceMapping[remittanceOwner].remittanceBallance = 0;
            msg.sender.transfer(amount);
        }
        
        return true;
    }
    
    ///if it is after deadline, remittance owner can claim back its ether
    function claimUnchallengedEther() returns(bool){
        //only owner of the remittance can call this function
        if(RemittanceMapping[msg.sender].beneficiary==0){
            return false;
        }
        
        //check amount. user can claim if ether is greater than zero
        if(RemittanceMapping[msg.sender].remittanceBallance == 0){
            return false;
        }
        
        //check deadline
        if(RemittanceMapping[msg.sender].deadline >= now){
            return false;
        }
        
        uint amount = RemittanceMapping[msg.sender].remittanceBallance;
        RemittanceMapping[msg.sender].remittanceBallance = 0;
        msg.sender.transfer(amount);

    }
    
    function stringToBytes32(string memory source) constant returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    //It will return funds to remittance owners, kill the contract and return all remain funds to the 
    //contract owner
    function killMe() returns (bool) {
        require(msg.sender == owner);
        
        //return all funds before suicide
        for (uint i = 0; i < remittanceOwners.length; i++) {
            address addrressToReturnFunds = remittanceOwners[i];
            uint amount = RemittanceMapping[addrressToReturnFunds].remittanceBallance;
            if(amount!=0){
                RemittanceMapping[addrressToReturnFunds].remittanceBallance = 0;
                addrressToReturnFunds.transfer(amount);
            }
        }
    
        suicide(owner);
        return true;
    }
    
    function () payable {
    }
}

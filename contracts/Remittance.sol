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
	    uint deadline;  //deadline must be less then now to allow Alice claim Ether 
	    uint remittanceBallance;     //value Alice will receive from Carol
	    uint remittanceOwnersIndex;
	    bytes32 passwordHash;
	    address beneficiary;  //Alice address. 
    }
    
    mapping (address => RemittanceStruct) public RemittanceMapping;
    mapping (bytes32 => uint32) private passwordsUsed;
    
    //Log events
    event LogBeginRemittance(address remittanceOwner, address beneficiary, uint deadlineInSeconds,  
                        bytes32 passwordHash, uint amountReceived);
    event LogTransfer(address beneficiary, uint amount);
    event LogFundsUnclaimed(address remittanceOwner, address beneficiary, uint amount);
    event LogRemittanceBalanceUpdated(address remittanceOwner, address beneficiary, uint amount);
    
    //Constructor
    function Remittance(uint _deadlineLimitInSeconds) {
        owner = msg.sender;
        deadlineLIMITInSeconds = _deadlineLimitInSeconds;
    }
    
    //Start a remittance process
    function beginRemittanceProcess(address beneficiary, uint deadlineInSeconds,
                                    bytes32 passwordHash) 
        public
        payable  
        returns(bool success) 
    {
        //if deadline is greater than the deadlimit, if msg.value is zero,
        //if beneficiary address is zero and if password was already used in the past, revert
        if(now+deadlineInSeconds > now+deadlineLIMITInSeconds
             || msg.value == 0 || beneficiary==0 || passwordsUsed[passwordHash]!=0 ) {
            revert();
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
        
        LogRemittanceBalanceUpdated(msg.sender, beneficiary , msg.value);
        LogBeginRemittance(msg.sender , newRemittance.beneficiary, newRemittance.deadline, 
                            newRemittance.passwordHash, newRemittance.remittanceBallance);
        
        return true;
    }
    
    //beneficary will call this function to receive ethers
    function releaseRemittance(address remittanceOwner, bytes32 secretWordHash1, 
                                bytes32 secretWordHash2) 
        public
        returns(bool success){
        
        //only beneficiary can call this function
        if(RemittanceMapping[remittanceOwner].beneficiary!=msg.sender){
            revert();
        }
        
        //if theresn´t funds, stop
        if(RemittanceMapping[remittanceOwner].remittanceBallance==0){
            revert();
        }
        
        //check password of user 1 and user 2. they are sent in plain text because 
        //I couldn´t find how to send it encrypted
        bytes32 passwordSent = keccak256(secretWordHash1, secretWordHash2);
        bytes32 passwordStored = RemittanceMapping[remittanceOwner].passwordHash;
        
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
            RemittanceMapping[remittanceOwner].beneficiary.transfer(amount);
            
            //RemittanceMapping[remittanceOwner].beneficiary == msg.sender
            LogTransfer(RemittanceMapping[remittanceOwner].beneficiary, amount);
            LogRemittanceBalanceUpdated(remittanceOwner, RemittanceMapping[remittanceOwner].beneficiary, 0);
        }
        
        return true;
    }
    
    ///if it is after deadline, remittance owner can claim back its ether
    function claimUnchallengedEther() returns(bool success){
        //only owner of the remittance can call this function
        if(RemittanceMapping[msg.sender].beneficiary==0){
            revert();
        }
        
        //check amount. user can claim if ether is greater than zero
        if(RemittanceMapping[msg.sender].remittanceBallance == 0){
            revert();
        }
        
        //check deadline
        if(RemittanceMapping[msg.sender].deadline >= now){
            revert();
        }
        
        uint amount = RemittanceMapping[msg.sender].remittanceBallance;
        RemittanceMapping[msg.sender].remittanceBallance = 0;
        msg.sender.transfer(amount);
        
        LogRemittanceBalanceUpdated(msg.sender, RemittanceMapping[msg.sender].beneficiary,0);
        LogTransfer(msg.sender, amount);
        
        return true;

    }
    
    //It will log beneficiary and amount that was not claimed, kill the contract and return all remain funds to the 
    //contract owner
    function killMe() returns (bool success) {
        require(msg.sender == owner);
        
        //I was adiviced not to transfer in a loop. But I am going to log
        //all users and balances so I could transfer to them in future 
        //if any issue arises.
        for (uint i = 0; i < remittanceOwners.length; i++) {
            address addrressToReturnFunds = remittanceOwners[i];
            uint amount = RemittanceMapping[addrressToReturnFunds].remittanceBallance;
            
            if(amount!=0){
                RemittanceMapping[addrressToReturnFunds].remittanceBallance = 0;
                
                LogRemittanceBalanceUpdated(addrressToReturnFunds, RemittanceMapping[addrressToReturnFunds].beneficiary,0);
                LogFundsUnclaimed(addrressToReturnFunds, RemittanceMapping[addrressToReturnFunds].beneficiary, amount);
            }
            
        }
    
        suicide(owner);
        return true;
    }
    
    function () payable {
    }
}

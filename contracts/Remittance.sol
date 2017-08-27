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
    mapping (bytes32 => bool) private passwordsAlreadyUsed;
    
    //Log events
    event LogRemittanceProcessStarted(address indexed remittanceOwner, address indexed beneficiary, 
                         uint deadlineInSeconds,  bytes32 passwordHash, uint amountReceived);
    event LogTransferred(address beneficiary, uint amount);
    
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
        if(deadlineInSeconds > deadlineLIMITInSeconds
             || msg.value == 0 || beneficiary==0 || passwordsAlreadyUsed[passwordHash]==true ) {
            revert();
        }
        
        RemittanceStruct memory newRemittance;
        newRemittance.deadline = now + deadlineInSeconds;
        newRemittance.remittanceBallance = msg.value;
        newRemittance.beneficiary = beneficiary;
        newRemittance.passwordHash = passwordHash;
        
        passwordsAlreadyUsed[passwordHash] = true;
        
        //if it is a new remittance, create a new index. otherwise, keep the last index
        if(RemittanceMapping[msg.sender].beneficiary==0){
            newRemittance.remittanceOwnersIndex = remittanceOwners.push(msg.sender)-1;
        }
        else{
            //do nothing, remittanceOwnersIndex is already populated with the correct index
        }
        
        RemittanceMapping[msg.sender] = newRemittance;
        
        LogRemittanceProcessStarted(msg.sender , newRemittance.beneficiary, newRemittance.deadline, 
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
        
        bytes32 passwordSent = keccak256(secretWordHash1, secretWordHash2);
        bytes32 passwordStored = RemittanceMapping[remittanceOwner].passwordHash;
        
        //if password sent doesn´t match, stop
        if(passwordStored != passwordSent){
            revert();
        }
        else{
            uint amount = RemittanceMapping[remittanceOwner].remittanceBallance;

            //msg.sender is the beneficary and it was checked in the first line of this function
            RemittanceMapping[remittanceOwner].remittanceBallance = 0;
            RemittanceMapping[remittanceOwner].beneficiary.transfer(amount);
        
            LogTransferred(RemittanceMapping[remittanceOwner].beneficiary, amount);
        }
        
        return true;
    }
    
    ///if it is after deadline, remittance owner can claim back its Ether
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
        
        LogTransferred(msg.sender, amount);
        
        return true;
    }
    
    //kill the contract and return all remain funds to the contract owner
    function killMe() returns (bool success) {
        require(msg.sender == owner);
        suicide(owner);
        return true;
    }
    
    function () {
    }
}

pragma solidity ^0.4.11;


/**
 * @title Remittance contract. 
 * Consensys Dev Academy exercise - Small projects - Module 4
 * 
 */
contract Remittance {
    
    //states
    address public owner;
    uint public deadlineLIMITInSeconds;  //remittance max period of time. after that, owner can claim funds
    
    struct RemittanceStruct { 
        address remittanceOwner;  //who starts the remittance
	    uint deadline;  //deadline must be less then now to allow Alice claim Ether 
	    uint remittanceBallance;     //value Alice will receive from Carol
	    address beneficiary;  //Alice address. 
    }
    
    //key is passwordHash
    mapping (bytes32 => RemittanceStruct) public RemittanceMapping;
    
    //Log events
    event LogRemittanceProcessStarted(address  remittanceOwner, address  beneficiary, 
                         uint deadlineInSeconds,  bytes32  passwordHash, uint amountReceived);
    event LogTransferred(address beneficiary, uint amount);
     event logs(bool beneficiary, bool amount, bytes32 asdf);
    
    //Constructor
    function Remittance(uint _deadlineLimitInSeconds) {
        owner = msg.sender;
        deadlineLIMITInSeconds = _deadlineLimitInSeconds;
    }
    
    //Start a remittance process
    //passwordHash is remittance id
    function beginRemittanceProcess(address beneficiary, uint deadlineInSeconds,
                                    bytes32 passwordHash) 
        public
        payable  
        returns(bool success) 
    {
        //if deadline is greater than the deadlimit, if msg.value is zero,
        //if beneficiary address is zero and if password was already used in the past, revert
        if(deadlineInSeconds > deadlineLIMITInSeconds
             || msg.value == 0 || beneficiary==0 
             || RemittanceMapping[passwordHash].deadline > 0 ) {
            revert();
        } 
        
        RemittanceStruct memory newRemittance;
        newRemittance.remittanceOwner = msg.sender; 
        newRemittance.deadline = now + deadlineInSeconds;
        newRemittance.remittanceBallance = msg.value;
        newRemittance.beneficiary = beneficiary;
        
        RemittanceMapping[passwordHash] = newRemittance;

                            
        LogRemittanceProcessStarted(msg.sender , newRemittance.beneficiary, newRemittance.deadline, 
                            passwordHash, newRemittance.remittanceBallance);
        
        return true;
    }
    
    //beneficary will call this function to receive ethers
    function releaseRemittance(bytes32 secretWordHash1 ,bytes32 secretWordHash2) 
        public
        returns(bool success)
    {
        
        bytes32 passwordSent = keccak256(secretWordHash1, secretWordHash2);

        //only beneficiary can call this function and it should have funds
        require(RemittanceMapping[passwordSent].beneficiary == msg.sender);
        require(RemittanceMapping[passwordSent].remittanceBallance > 0);
        
        uint amount = RemittanceMapping[passwordSent].remittanceBallance;

        //msg.sender is the beneficary and it was checked in the first line of this function
        RemittanceMapping[passwordSent].remittanceBallance = 0;
        
        RemittanceMapping[passwordSent].beneficiary.transfer(amount);
        
        LogTransferred(RemittanceMapping[passwordSent].beneficiary, amount);
        
        return true;
    }
    
    ///if it is after deadline, remittance owner can claim back its Ether
    function claimUnchallengedEther(bytes32 passwordHash) 
        public
        returns(bool success)
    {
        
        //only owner of the remittance can call this function
        //it should exist and it should have funds and it should have been beyond deadline
        require(RemittanceMapping[passwordHash].deadline < now);
        require(RemittanceMapping[passwordHash].remittanceBallance > 0);
        require(RemittanceMapping[passwordHash].remittanceOwner == msg.sender);
        
        uint amount = RemittanceMapping[passwordHash].remittanceBallance;
        RemittanceMapping[passwordHash].remittanceBallance = 0;
        
        msg.sender.transfer(amount);
        
        LogTransferred(msg.sender, amount);
        
        return true;
    }
    
    //kill the contract and return all remain funds to the contract owner
    function killMe() 
        public
        returns (bool success)
    {
        require(msg.sender == owner);
        uint amount = this.balance;
        
        selfdestruct(owner);
        
        LogTransferred(msg.sender, amount);
        return true;
    }
    
    function () {
    }
}

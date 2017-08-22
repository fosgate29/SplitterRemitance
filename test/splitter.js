var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
  
  var contract;

  var owner = accounts[0];
  var alice = accounts[1];  var aliceContribution = 10;
  var bob   = accounts[2];   
  var carol = accounts[3];

  var someUser = accounts[4]; var contributionSomeUser = 10;
 
  beforeEach(function() {
    return Splitter.new({from:owner})
    .then(function(instance) {
      contract = instance;
    })
  });

  it("should be owned by owner", function(){
    return contract.owner({from:owner})
    .then(function(_owner){
      assert.strictEqual(_owner, owner, "Contract is not owned by owner");
      });
  });

 
  it("should start with accounts being different", function(){
    return contract.startSplitter(bob, bob, {from:alice})
    .then(function(isSplitterStartedObject){
      assert.strictEqual(false, isSplitterStartedObject.logs[0].args.isCreated, "Splitter has same receivers");      
    });   
  });

  it("should start with accounts being different", function(){
    return contract.startSplitter(bob, 0, {from:alice})
    .then(function(isSplitterStartedObject){
      assert.strictEqual(false, isSplitterStartedObject.logs[0].args.isCreated, "Splitter started with an address equal to zero.");      
    });   
  });

  it("should let Alice send funds before creating the Splitter and contract gets the amount", function(){
    return contract.send(2,{from:alice, value:2})
    .then(function(txn){
        return contract.getBalance({from:owner})
        .then(function(balance){
             assert.strictEqual(2, balance.toNumber(), "Contract didn't receive correct amount");
        })              
     });
  });


  it("should start the Splitter, Alice will send funds to the contract and the funds are splitted between Bob and Carol", function(){
    return contract.startSplitter(bob, carol, {from:alice})
    .then(function(txn){
         //return contract.send(5,{from:alice, value:5})
         web3.eth.sendTransaction({from:alice , to:contract.address , value:3})
         var finalBalance = contract.getUserBalance(bob,{from:owner}) ;
         //assert.strictEqual(finalBalance, 2.5 , "Bob didn't receive correct amount");             
    })
  });

});

const { constants } = require('openzeppelin-test-helpers');
const { ZERO_ADDRESS } = constants;

const Splitter = artifacts.require("./Splitter.sol");

const Promise = require("bluebird");
const { shouldFail } = require("openzeppelin-test-helpers");

web3.eth = Promise.promisifyAll(web3.eth);

contract('Splitter', function(accounts) {
  
  let contract;

  const owner = accounts[0]; 

  const contribution = web3.utils.toWei(web3.utils.toBN(1), 'ether');
  
  const bob   = accounts[2];   
  const carol = accounts[3];

  const someUser = accounts[4];

  beforeEach(async () => {
    contract = await Splitter.new({from:owner})
  });

  it("should be owned by owner", async () => {
    const _owner = await contract.owner({from:owner})
    assert.strictEqual(_owner, owner, "Contract is not owned by owner");
  });

  it("should be possible to start a split", async () => {
    const successful = await  contract.split.call(bob, carol, { from: owner , to:contract.address, value:contribution })
    assert.isTrue(successful, "Split didnt start with success");        
  });

  it("should not be possible to start a split with a 0 address", async () => {
    await shouldFail.reverting(contract.split.call(ZERO_ADDRESS,carol ,{ from: owner, value: 9 }));
  });

  it("should not be possible to start a split with a 0 value", async () => {
    await shouldFail.reverting(contract.split(carol,bob ,{ from: owner, value: 0 }));    
  });

  it("should not be possible to kill the contract if it is not the owner", async () => {
    await shouldFail.reverting(contract.killMe({ from: bob }));
  });

  it("should not be possible to withdraw funds if user balance is 0", async () => {
    await shouldFail.reverting(contract.withdrawFunds({ from: someUser }));
  });

  it("should be possible to start a split with value = 10 and bob and carol gets half (5) each one", async () => {
    const expectedValue = contribution.div(new web3.utils.BN(2));
    let bobBalance = 0;
    let carolBalance = 0;
    await contract.split(carol, bob, { from: owner , to:contract.address, value:contribution })
    bobBalance = await contract.balances(bob);
    carolBalance = await contract.balances(carol);

    const total = bobBalance.add(carolBalance);
    assert.isTrue(bobBalance.eq(expectedValue) , "Bob didn't receive correct amount."); 
    assert.isTrue(carolBalance.eq(expectedValue) , "Carol didn't receive correct amount.");
    assert.isTrue(total.eq(contribution), "Total contribution is not correct.");
  });

  it("should be possible to start a split with value = 11 and bob and carol gets half (5) each one and 1 remained is for the smart contract balance", async () => {
    const contributionNormal = web3.utils.toWei(web3.utils.toBN(1), 'ether');

    const contributionOdd = contributionNormal.add(web3.utils.toBN(1));


    let bobBalance = 0;
    let carolBalance = 0;
    let spliterBalance = 0;
    await contract.split(carol, bob, { from: owner , to:contract.address, value:contributionOdd })
    
    bobBalance = await contract.balances(bob);
    carolBalance = await contract.balances(carol);
    spliterBalance = await web3.eth.getBalance(contract.address);
    spliterBalance = web3.utils.toBN(spliterBalance);

    const total = bobBalance.add(carolBalance).add(web3.utils.toBN(1));

    assert.isTrue(total.eq(contributionOdd), "Total contribution is not correct.");
    assert.isTrue(total.eq(spliterBalance), "Total contribution is not equal to Splitter balance.");
  });  

  it("should be possible to Bob to withdraw his funds", async () => {  
    const valueToTest = new web3.utils.toBN("20000000000000000000");

    let bobInitialBalance = await web3.eth.getBalance(bob);
    bobInitialBalance = new web3.utils.toBN(bobInitialBalance);
    
    const bobInitialContractBalance = await contract.balances(bob);
    assert.strictEqual(bobInitialContractBalance.toNumber(), 0 , "Bob initial balance inside Splitter contract is not zero.");
   
    await contract.split(bob, carol, { from: owner , to:contract.address, value:valueToTest })
    
    const bobContractBalanceAfterSplit = await contract.balances(bob);

    assert.isTrue(bobContractBalanceAfterSplit.eq(valueToTest.div(new web3.utils.BN(2))), "Bob balance after split is wrong.");
    
    await contract.withdrawFunds( { from: bob} );
    let _bobSplitBalance = await contract.balances(bob);

    assert.strictEqual(_bobSplitBalance.toNumber(), 0 , "Bob balance inside Splitter contract is wrong.");

    let bobEndBalance = await web3.eth.getBalance(bob);
    bobEndBalance = new web3.utils.toBN(bobEndBalance);

    assert.isTrue(bobEndBalance.gt(bobInitialBalance) , "Bob balance in the blockchain is wrong. ");          
  });

  it("should not be possible to kill Splitter if not owner", async () => {
    await shouldFail.reverting(contract.killMe({ from: bob }));
  });

  it("should be possible to kill Splitter", async () => {
    await contract.killMe({ from: owner });
  }); 
});

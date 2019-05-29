const { constants } = require('openzeppelin-test-helpers');
const { ZERO_ADDRESS } = constants;

const Remittance = artifacts.require("./Remittance.sol");

const Promise = require("bluebird");
const { shouldFail } = require("openzeppelin-test-helpers");

web3.eth = Promise.promisifyAll(web3.eth);

contract('Remittance', function(accounts) {
  
  let contract;

  const owner = accounts[0]; 

  const contribution = web3.utils.toWei(web3.utils.toBN(1), 'ether');
  
  const bob   = accounts[2];   
  const carol = accounts[3];

  const someUser = accounts[4];

  beforeEach(async () => {
    contract = await Remittance.new(1000, {from:owner})
  });

  it("should be owned by owner", async () => {
    const _owner = await contract.owner({from:owner})
    assert.strictEqual(_owner, owner, "Contract is not owned by owner");
  });

  it("should not be possible to kill Splitter if not owner", async () => {  
    await shouldFail.reverting(contract.killMe({ from: bob }));  
  });  

  it("should be possible to kill Splitter", async () => {  
    await contract.killMe({ from: owner });
  });   

  

});

var Splitter = artifacts.require("./Splitter.sol");

// Found here https://gist.github.com/xavierlepretre/88682e871f4ad07be4534ae560692ee6
web3.eth.getTransactionReceiptMined = function (txnHash, interval) {
  var transactionReceiptAsync;
  interval = interval ? interval : 500;
  transactionReceiptAsync = function(txnHash, resolve, reject) {
    try {
      var receipt = web3.eth.getTransactionReceipt(txnHash);
      if (receipt == null) {
        setTimeout(function () {
          transactionReceiptAsync(txnHash, resolve, reject);
        }, interval);
      } else {
        resolve(receipt);
      }
    } catch(e) {
      reject(e);
    }
  };

  return new Promise(function (resolve, reject) {
      transactionReceiptAsync(txnHash, resolve, reject);
  });
};

// Found here https://gist.github.com/xavierlepretre/afab5a6ca65e0c52eaf902b50b807401
var getEventsPromise = function (myFilter, count) {
  return new Promise(function (resolve, reject) {
    count = count ? count : 1;
    var results = [];
    myFilter.watch(function (error, result) {
      if (error) {
        reject(error);
      } else {
        count--;
        results.push(result);
      }
      if (count <= 0) {
        resolve(results);
        myFilter.stopWatching();
      }
    });
  });
};

// Found here https://gist.github.com/xavierlepretre/d5583222fde52ddfbc58b7cfa0d2d0a9
var expectedExceptionPromise = function (action, gasToUse) {
  return new Promise(function (resolve, reject) {
      try {
        resolve(action());
      } catch(e) {
        reject(e);
      }
    })
    .then(function (txn) {
      return web3.eth.getTransactionReceiptMined(txn);
    })
    .then(function (receipt) {
      // We are in Geth
      assert.equal(receipt.gasUsed, gasToUse, "should have used all the gas");
    })
    .catch(function (e) {
      if ((e + "").indexOf("invalid opcode") > -1) {
        // We are in TestRPC
      } else {
        throw e;
      }
    });
};

contract('Splitter', function(accounts) {
  
  var contract;

  var owner = accounts[0];
  var alice = accounts[1];  

  var contribution = web3.toWei(1, 'ether');
  
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

  it("should be possible to start a split", function() {
    return contract.split.call(bob, carol, { from: owner , to:contract.address, value:contribution })
      .then(function(successful) {
        assert.isTrue(successful, "Split didnt start with success");        
      });
  });

  it("should not be possible to start a split with a 0 address", function() {
    return expectedExceptionPromise(function () {
      return contract.split.call(0,bob ,{ from: owner, value: 9, gas: 3000000 });     
        },
        3000000);
  });

  it("should not be possible to start a split with a 0 value", function() {
    return expectedExceptionPromise(function () {
      return contract.split.call(carol,bob ,{ from: owner, value: 0, gas: 3000000 });     
        },
        3000000);
  });

  it("should not be possible to kill the contract if it is not the owner", function() {
    return expectedExceptionPromise(function () {
      return contract.killMe.call({ from: bob });     
        },
        3000000);
  });

  it("should not be possible to withdraw funds if user balance is 0", function() {
    return expectedExceptionPromise(function () {
      return contract.withdrawFunds.call({ from: someUser });     
        },
        3000000);
  });


  it("should be possible to start a split with value = 10 and bob and carol gets half (5) each one", function() {
    var expectedValue = contribution / 2;
    var bobBalance = 0;
    var carolBalance = 0;
    contract.split.sendTransaction(bob, carol, { from: owner , to:contract.address, value:contribution })
    .then(function(txHash){
        return contract.balances(bob)
      .then(function(_bobBalance){
        bobBalance = _bobBalance;
        return contract.balances(carol)
      })
      .then(function(_carolBalance){
        var total = bobBalance.plus(_carolBalance);
        assert.strictEqual(bobBalance.toNumber(), expectedValue , "Bob didn't receive correct amount."); 
        assert.strictEqual(_carolBalance.toNumber(), expectedValue , "Carol didn't receive correct amount.");
        assert.strictEqual(total.toString(10), contribution , "Total contribution is not correct.");

      })
     
    });
  });

  it("should be possible to Bob to withdraw his funds", function() {    
    var bobSplitBalance = 0;
    var bobInitialBalance = web3.eth.getBalance(bob).toNumber();
    var valueToTest = web3.toWei(2, 'ether');
    contract.balances(bob)
      .then(function(_bobInitialContractBalance){
        assert.strictEqual(_bobInitialContractBalance.toNumber(), 0 , "Bob initial balance inside Splitter contract is not zero.");
        return contract.split.sendTransaction(bob, carol, { from: owner , to:contract.address, value:valueToTest })
      .then(function(txHash){
          return contract.balances(bob)
        .then(function(_bobContractBalanceAfterSplit){
          assert.strictEqual(_bobContractBalanceAfterSplit.toNumber(), valueToTest / 2, "Bob balance after split is wrong.");
          return contract.withdrawFunds.sendTransaction( { from: bob} )
        })          
        .then(function(txHash2){
          return contract.balances(bob)
        })
        .then(function(_bobSplitBalance){
          bobSplitBalance = _bobSplitBalance.toNumber();
          var bobEndBalance = web3.eth.getBalance(bob).toNumber();
          assert.strictEqual(bobSplitBalance, 0 , "Bob balance inside Splitter contract is wrong.");
          assert.isAbove(bobEndBalance, bobInitialBalance , "Bob balance in the blockchain is wrong. ");
        })    
      });
    });
  });

});

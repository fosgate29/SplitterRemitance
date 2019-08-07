[![CircleCI](https://circleci.com/gh/fosgate29/SplitterRemitance/tree/master.svg?style=shield)](https://circleci.com/gh/fosgate29/SplitterRemitance/tree/master)
[![Coverage Status](https://coveralls.io/repos/github/fosgate29/SplitterRemitance/badge.svg)](https://coveralls.io/github/fosgate29/SplitterRemitance)

These contracts have **not** been audited, use them with caution.

# Splitter
SPLITTER is a smart contract where one address sends Ether to the contract and half of it goes to address#2 and the other half to address#3

It has a kill switch.

# Remittance
REMITTANCE is a smart contract where address#1 sends funds to address#2 and address#3 can withdraw it with a password. It has a deadline where address#1 can claim back the unchallenged Ether and it has a kill switch.

## License

MIT

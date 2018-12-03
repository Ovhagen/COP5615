# Project 4.1
A project in the course Distributed Operating System Principles COP5615. The task for this project was to implement the Bitcoin protocol with sufficient functionality to receve, send, and mine the digital currency that is Bitcoin. Futhermore, tests were implemented to test the correctness of each task.

### Author
James Howes (UFID 9262-9312)
Lars Pontus Ovhagen (UFID 2992-9498)

## Installation
Download the project zip to your desired location and unzip. Make sure you have Elixir/Erlang installed on your computer and that it is in the OS path for easy command access.

## Running the bitcoin tests
To run the tests, change directory into `/proj4/` and write the following test calls to test independent correctness of bitcoin functionality. Please refer to the test source code for further test specific details.

### Keyaddress test
This test performs a simple generation of an address from a public key hash. It also tests compression and uncompression of the pubkey. To run the test, use the following command:
```sh
$ mix test test/Proj4/keyaddress_test.exs
```
Refer to the file `test/Proj4/keyaddress_test.exs` for further specification on the keyaddress test.
### Transaction test
The transaction test important aspects of the transaction implementation such as verification, serilization, byte size calculation, and finally the verification of a coinbase transaction.
```sh
$ mix test test/Proj4/transaction_test.exs
```
Refer to the file `test/Proj4/transaction_test.exs` for further specification on the test for transactions.
### Merkle Tree test
The merkle tree test concerns the testing of functionality when creating a merkle tree as well as proof verifications and failures. This test module defines 5 tests in total. To run independent merkle tree tests, use the following command for executing the test script:
```sh
$ mix test test/Proj4/merkle_tree_test.exs
```
Refer to the file `test/Proj4/merkle_tree_test.exs` for further specification on the merkle tree test.
### Block test
To test the block implementation, we have outlined three tests for checking byte size and serilazation correctness as well as the verification of a block. The test can be executed with the command given below:
```sh
$ mix test test/Proj4/block_test.exs
```
Refer to the file `test/Proj4/block_test.exs` for further specification on tests for the block implemention.
### Blockchain test

### Miner test



## Funtionality Specification (What works?)
The bulletpoints below outline what parts are working and have been incorporated into this first project.
__Miner__
* Miners can successfully mine blocks.
* A miner can store a local copy of a blockchain to update as they verify blocks.
* 

__Blocks/Blockchain__
* A block can be created with a block header
* Blocks can be verified based on metrics for correctness of the block hash, timestamp, the root hash, and on meeting the difficulty target.
* A set of transactions can be used to create a merkle tree strucutre, which yields a root hash.
* A merkle proof can be created as the merkle path for a specific transaction. After creation, this proof can be verified against the root hash of a block.
* Blockchains can be verified...
__Wallet/transactions__
* A transaction can be created with inputs and outputs.
* Transactions can be signed and verified.
* Keyaddresses...



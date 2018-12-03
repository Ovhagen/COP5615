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

__Keys and Addresses__
* Public/private key pairs can be generated with a specific seed, or using a random seed.
* Public keys can be converted into a bitcoin address, which is a hash of the public key encoded into Base58Check.
* Public keys are "compressed" in all transactions. This reduces the byte size of the key by half.

__Transactions__
* To greatly simplify our implementation, we only allow pay-to-public-key-hash (P2PKH) transactions. The overwhelming majority of bitcoin transactions are of this type.
* This allowed us to remove the scripting language used in the real bitcoin. Transaction outputs simply store the public key hash where the coins are being sent, instead of an output locking script.
* Transactions can be created with up to 255 inputs and up to 255 outputs, and the total input value must exceed the total output value (i.e. positive transaction fee).
* Transactions can be cryptographically signed, and the signatures can be verified.
* Coinbase transactions, which are used to claim the mined block reward, can include an arbitrary message of up to 34 bytes.
* Transactions can be serialized into raw bytes, and then deserialized back into the transaction data for transmission across a network.

__Blocks__
* Blocks can be created from an arbitrary number of transactions.
* Blocks include a header which contains the version number, a timestamp, the hash of the previous block, the root hash of the transaction merkle tree, a mining difficulty target, and a nonce.
* A merkle tree is built from the transaction data which allows anyone to prove a transaction was contained within the block.

__Blockchain__
* Blockchains can be built starting from a hard-coded genesis block. The genesis block starts with 1 billion coins sent to a single address.
* Each blockchain data structure maintains a linked list of blocks in the chain, plus a pool of valid unconfirmed transactions (mempool) and an index of all unspent outputs (UTXOs).
* New transactions can verified and added to the mempool if they meet all requirements.
* New blocks can be verified and added to the chain if they meet all requirements. When a new block is added, the mempool and UTXO index are updated with the changes from the new block.

__Mining__
* Blocks can be mined using the same proof-of-work requirements as the real bitcoin.
* The mining difficulty is currently fixed and does not change with network hashing power. A block can be mined in a fraction of a second on a typical CPU.
* The block reward (coinbase output) can be sent to a single address specified by the miner. Block rewards are also fixed.

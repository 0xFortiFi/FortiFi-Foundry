
![Logo](https://372453455-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F43popf5VC0KlvwcpE7fk%2Fuploads%2FxXBnexrGFEUHxjAO3CZP%2FFortiFi-Word-light-press.png?alt=media&token=534aff84-e551-42f0-b1f1-2b32d3ee83f5)


## Authors

- [@xrpant](https://www.github.com/anthonybautista)


## Introduction

This repository contains all of the contracts related to the FortiFi Vaults Ecosystem, as well as a base test file for writing tests in Foundry. This base test file has all of the currently deployed contracts so that it is easy to run fork testing. 

POC tests are moved to the test-poc folder after use so that users don't need to wait for multiple tests to run when they are only testing a specific scenario.

To get started, clone the repo and install the below dependencies:

```forge install openzeppelin/openzeppelin-contracts@v4.5.0```

```forge install foundry-rs/forge-std```

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

<h2 align="center">
  DetaskDAO Contracts
</h2>
<p align="center">
  Trust Web3 Freelance Solution.
</p>

<p align="center">
  <a href="https://github.com/DetaskDAO/contracts/">
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="mit license"/>
  </a>
</p>

## Setup

```sh
git clone https://github.com/DetaskDAO/contracts.git
cd contracts
npm install
```

## Run Tests

This repository is a hybrid hardhat and forge project.
First install the relevant dependencies of the project:
```sh
npm install
forge install foundry-rs/forge-std --no-commit
forge install https://github.com/Uniswap/permit2 --no-commit
```
To run tests:
```
forge test
```

## Deploy

```sh
sh ./dev_deploy.sh <NETWORK>
```

## License

[MIT License](LICENSE).
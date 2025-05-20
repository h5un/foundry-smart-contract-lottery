# Foundry Smart Contract Lottery F23

This project is a decentralized lottery application built using Foundry. The application allows users to participate in a lottery where a winner is selected randomly based on blockchain data.

## Features

- **Decentralized Lottery**: A trustless lottery system where participants can enter and a winner is chosen randomly.
- **Chainlink VRF Integration**: Ensures randomness in winner selection using Chainlink's Verifiable Random Function (VRF).
- **Automated Execution**: Uses Chainlink Keepers(Automation) to automate the lottery lifecycle.

## Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/your-username/foundry-smart-contract-lottery-f23.git
    cd foundry-smart-contract-lottery-f23
    ```

2. Install dependencies:
    ```bash
    forge install
    ```

3. Compile the contracts:
    ```bash
    forge build
    ```

4. Run tests:
    ```bash
    forge test
    ```

## Deployment

1. Configure environment variables in a `.env` file:
    ```plaintext
    SEPOLIA_RPC_URL=
    PRIVATE_KEY=
    ETHERSCAN_API_KEY=
    ```

2. Deploy the contract:
    ```bash
    forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
    ```

## Usage

1. Enter the lottery by sending ETH to the contract.
2. Wait for the lottery to close and a winner to be selected.
3. The winner receives the accumulated prize pool.

## Testing

Run the test suite to ensure the contracts work as expected:
```bash
forge test
```

## Technologies Used

- **Foundry**: Development framework for Ethereum smart contracts.
- **Chainlink VRF**: For secure and verifiable randomness.
- **Chainlink Keepers**: For automating contract execution.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Chainlink Documentation](https://docs.chain.link/)

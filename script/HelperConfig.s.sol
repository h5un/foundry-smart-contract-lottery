// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337; // Anvil
    /* VRF Mock Values */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK =1e9;
    int256 public MOCK_WEI_PER_UINT_LINK = 4e16;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator; 
        bytes32 gasLane;
        uint256 subId;
        uint32 callbackGasLimit;
        address link;
        address account;
    }   

    NetworkConfig public localNetworkConfig;
    mapping (uint chainId => NetworkConfig) networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId() public returns (NetworkConfig memory) {
        uint256 chainId = block.chainid;
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        }
        else if(chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        }
        else
            revert HelperConfig__InvalidChainId();
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 sec
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subId: 20203108466552120891370721060025503630783764295842446038882791684450461419710,
            callbackGasLimit: 500000, // 500,000 gas
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xD67D3ADc8c57840fA5B1a57EE1B5955675bf7b62 // My foundry wallet
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory){
        if (localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }

        // Deploy mocks
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,
        MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 sec
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subId: 0,
            callbackGasLimit: 500000, // 500,000 gas
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 // Default sender in foundry
        });

        return localNetworkConfig;
    }
}
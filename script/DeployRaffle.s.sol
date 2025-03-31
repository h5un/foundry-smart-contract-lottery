// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script, HelperConfig {
    function run() external returns (Raffle, HelperConfig) {
        return deployRaffle();
    }

    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        // Local -> deploy mocks and get local configs
        // Sepolia -> get Sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId();

        // Automate the subscription
        if (config.subId == 0) {
            // Create Subscription
            CreateSubscription subscriptionCreator = new CreateSubscription();
            (config.subId,) = subscriptionCreator.createSubscription(config.vrfCoordinator, config.account);
            // (config.subId,) = subscriptionCreator.run(); // This will fail test

            // Fund the subscription
            FundSubscription subscriptionFunder = new FundSubscription();
            subscriptionFunder.fundSubscription(config.vrfCoordinator, config.subId, config.link, config.account);
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle
        (
            config.entranceFee, 
            config.interval, 
            config.vrfCoordinator, 
            config.gasLane, 
            config.subId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // Raffle deployed, add it to the consumers
        AddConsumer adder = new AddConsumer();
        adder.addConsumer(address(raffle), config.vrfCoordinator, config.subId, config.account);
        return (raffle, helperConfig);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function run() public returns (uint256 subId, address) {
        return createSubscriptionByConfig();
    }

    function createSubscriptionByConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId().vrfCoordinator;
        address account = helperConfig.getConfigByChainId().account;
        return createSubscription(vrfCoordinator, account);

    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console.log("Creating subscription on chain: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription ID is: ", subId);
        return (subId, vrfCoordinator);
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId().vrfCoordinator;
        uint256 subId = helperConfig.getConfigByChainId().subId;
        address linkToken = helperConfig.getConfigByChainId().link;
        address account = helperConfig.getConfigByChainId().account;
        // Get the configs and call fund function
        fundSubscription(vrfCoordinator, subId, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken, address account) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT); 
            // Call the fund function in the contract
            vm.stopBroadcast();
        }
        else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external { fundSubscriptionUsingConfig(); }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId().vrfCoordinator;
        uint256 subId = helperConfig.getConfigByChainId().subId;
        address account = helperConfig.getConfigByChainId().account;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer
    (
        address contractToAddToVrf, 
        address vrfCoordinator, 
        uint256 subId,
        address account
    ) 
        public 
    {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() external { 
        // Grab the most recent "Raffle" contract and add it to the consumers
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
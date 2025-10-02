// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Subscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // LINK

    function run() public {
        createSubscriptionUsingConfig();
        fundSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address vrfCoordinator = config.vrfCoordinator;
        return createSubscription(vrfCoordinator, config.account);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        console.log("Creating subscription on chain id: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Created subscription with id: ", subId);
        return (subId, vrfCoordinator);
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address vrfCoordinator = config.vrfCoordinator;
        uint256 subId = config.subscriptionId;
        address linkToken = config.link;
        fundSubscription(subId, vrfCoordinator, linkToken, config.account);
    }

    function fundSubscription(
        uint256 subId,
        address vrfCoordinator,
        address linkToken,
        address account
    ) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On chain id: ", block.chainid);

        if (block.chainid == ETH_LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT * 100000
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }
}

contract Consumer is Script {
    function run() public {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentDeployment);
    }

    function addConsumerUsingConfig(address mostRecentDeployment) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address vrfCoordinator = config.vrfCoordinator;
        uint256 subId = config.subscriptionId;
        addConsumer(mostRecentDeployment, vrfCoordinator, subId, config.account);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account)  public {
        console.log("Adding consumer to VRF coordinator: ", contractToAddToVrf);
        console.log("To VRF coordinator: ", vrfCoordinator);
        console.log("On chain id: ", block.chainid);
        
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }
}

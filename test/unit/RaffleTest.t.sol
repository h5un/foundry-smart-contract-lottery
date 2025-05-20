// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: config.entranceFee}();
        vm.warp(block.timestamp + config.interval + 1); // // Change the block time
        vm.roll(block.number + 1); // // Change the block number
        _;
    }

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        config = helperConfig.getConfigByChainId();

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN); // To get enum data type
    }

    function testRevertedWhenNotEnoughEntranceFee() public {
        // Arrange 
        vm.prank(PLAYER);
        // Act / Asset
        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffle.enterRaffle(); // Enter without sending any money
    }

    function testEnteringRaffleEmitEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER); // We emit the expected event first
        raffle.enterRaffle{value: config.entranceFee}();
    }

    function testRaffleClosedWhileCalculating() public raffleEntered {
        raffle.performUpkeep(""); // Now the raffle is temporary closed

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: config.entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEPP
    //////////////////////////////////////////////////////////////*/
    function testCheckUpkeepReturnsFalseWhenNoBalance() public {
        vm.warp(block.timestamp + config.interval + 1); // Change the block time
        vm.roll(block.number + 1); // Change the block number
        console.log("Raffle Balance:", address(raffle).balance);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/
    function  testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEntered{
        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertIfCheckUpkeepIsFalse() public {
        uint256 curBalance = 0;
        uint256 numOfPlayers = 0;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, curBalance, numOfPlayers, raffleState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        // Arrange: raffleEntered

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1); // 0 = open, 1 = calculating
    }

    function testGetPlayer() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: config.entranceFee}();

        // Act
        address player = raffle.getPlayer(0);

        // Assert
        assertEq(player, PLAYER);
    }
    
    function testGetNumOfPlayers() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: config.entranceFee}();

        // Act
        uint256 numOfPlayers = raffle.getNumOfPlayers();

        // Assert
        assertEq(numOfPlayers, 1);
    }
}
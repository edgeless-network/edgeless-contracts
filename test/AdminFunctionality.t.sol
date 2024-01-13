// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/src/Vm.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

import { EdgelessDeposit } from "../src/EdgelessDeposit.sol";
import { StakingManager } from "../src/StakingManager.sol";
import { WrappedToken } from "../src/WrappedToken.sol";
import { EthStrategy } from "../src/strategies/EthStrategy.sol";
import { DaiStrategy } from "../src/strategies/DaiStrategy.sol";

import { IDAI } from "../src/interfaces/IDAI.sol";
import { IL1StandardBridge } from "../src/interfaces/IL1StandardBridge.sol";
import { ILido } from "../src/interfaces/ILido.sol";
import { IUSDT } from "../src/interfaces/IUSDT.sol";
import { IUSDC } from "../src/interfaces/IUSDC.sol";
import { IWithdrawalQueueERC721 } from "../src/interfaces/IWithdrawalQueueERC721.sol";
import { IStakingStrategy } from "../src/interfaces/IStakingStrategy.sol";

import { Permit, SigUtils } from "./SigUtils.sol";
import { DeploymentUtils } from "./DeploymentUtils.sol";
import { LIDO, DAI, USDC, USDT } from "../src/Constants.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract AdminFunctionalityTest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
    using SigUtils for Permit;

    EdgelessDeposit internal edgelessDeposit;
    WrappedToken internal wrappedEth;
    WrappedToken internal wrappedUSD;
    IL1StandardBridge internal l1standardBridge;
    StakingManager internal stakingManager;
    IStakingStrategy internal ethStakingStrategy;
    IStakingStrategy internal daiStakingStrategy;

    address public constant STETH_WHALE = 0x5F6AE08B8AeB7078cf2F96AFb089D7c9f51DA47d; // Blast Deposits

    uint32 public constant FORK_BLOCK_NUMBER = 18_950_000;

    address public owner = makeAddr("Edgeless owner");
    address public depositor = makeAddr("Depositor");
    address public staker = makeAddr("Staker");

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        vm.createSelectFork({
            urlOrAlias: string(abi.encodePacked("https://eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
            blockNumber: FORK_BLOCK_NUMBER
        });

        (stakingManager, edgelessDeposit, wrappedEth, wrappedUSD, ethStakingStrategy, daiStakingStrategy) =
            deployContracts(owner, staker);
    }

    // ----------- Edgeless Deposit ------------
    function test_setL1StandardBridge(address randomL1StandardBridge, address randomUser) external {
        vm.assume(randomL1StandardBridge != address(0));
        vm.prank(owner);
        edgelessDeposit.setL1StandardBridge(IL1StandardBridge(randomL1StandardBridge));
        assertEq(address(edgelessDeposit.l1standardBridge()), randomL1StandardBridge);

        vm.prank(randomUser);
        vm.expectRevert();
        edgelessDeposit.setL1StandardBridge(IL1StandardBridge(randomL1StandardBridge));
    }

    function test_setL2Eth(address randomL2Eth, address randomUser) external {
        vm.assume(randomL2Eth != address(0));
        vm.prank(owner);
        edgelessDeposit.setL2Eth(randomL2Eth);
        assertEq(address(edgelessDeposit.l2ETH()), randomL2Eth);

        vm.prank(randomUser);
        vm.expectRevert();
        edgelessDeposit.setL2Eth(randomL2Eth);
    }

    function test_setL2USD(address randomL2Usd, address randomUser) external {
        vm.assume(randomL2Usd != address(0));
        vm.prank(owner);
        edgelessDeposit.setL2USD(randomL2Usd);
        assertEq(address(edgelessDeposit.l2USD()), randomL2Usd);

        vm.prank(randomUser);
        vm.expectRevert();
        edgelessDeposit.setL2USD(randomL2Usd);
    }

    function test_setAutoBridge(bool autoBridge, address randomUser) external {
        vm.prank(owner);
        edgelessDeposit.setAutoBridge(autoBridge);
        assertEq(edgelessDeposit.autoBridge(), autoBridge);

        vm.prank(randomUser);
        vm.expectRevert();
        edgelessDeposit.setAutoBridge(autoBridge);
    }

    // ----------- Staking Manager ------------
    function test_stake(uint256 amount, address randomUser) external {
        amount = bound(amount, 1e18, 1e23);
        address ethAddress = stakingManager.ETH_ADDRESS();
        vm.deal(address(edgelessDeposit), amount);
        vm.prank(owner);
        stakingManager.setAutoStake(false);

        vm.prank(address(edgelessDeposit));
        stakingManager.stake{ value: amount }(ethAddress, amount);

        vm.deal(randomUser, amount);
        vm.expectRevert();
        vm.prank(randomUser);
        stakingManager.stake{ value: amount }(ethAddress, amount);
    }

    function test_withdraw(address randomUser) external {
        address ethAddress = stakingManager.ETH_ADDRESS();

        vm.prank(address(edgelessDeposit));
        stakingManager.withdraw(ethAddress, 0);

        vm.prank(randomUser);
        vm.expectRevert();
        stakingManager.withdraw(ethAddress, 0);
    }

    function test_setStaker(address randomStaker, address randomUser) external {
        vm.prank(owner);
        stakingManager.setStaker(randomStaker);
        assertEq(stakingManager.staker(), randomStaker);

        vm.prank(randomUser);
        vm.expectRevert();
        stakingManager.setStaker(randomStaker);
    }

    function test_setDepositor(address randomDepositor, address randomUser) external {
        vm.prank(owner);
        stakingManager.setDepositor(randomDepositor);
        assertEq(stakingManager.depositor(), randomDepositor);

        vm.prank(randomUser);
        vm.expectRevert();
        stakingManager.setDepositor(randomDepositor);
    }

    function test_setAutoStake(bool autoStake, address randomUser) external {
        vm.prank(owner);
        stakingManager.setAutoStake(autoStake);
        assertEq(stakingManager.autoStake(), autoStake);

        vm.prank(randomUser);
        vm.expectRevert();
        stakingManager.setAutoStake(autoStake);
    }

    function test_addStrategy(address asset, IStakingStrategy strategy, address randomUser) external {
        vm.prank(owner);
        stakingManager.addStrategy(asset, strategy);
        assertEq(address(stakingManager.strategies(asset, 0)), address(strategy));

        vm.prank(randomUser);
        vm.expectRevert();
        stakingManager.addStrategy(asset, strategy);
    }

    function test_setActiveStrategy() external { }
    function test_removeStrategy() external { }

    // ----------- Eth Strategy ------------
    function test_ownerDepositEth() external { }
    function test_ownerWithdrawEth() external { }
    function test_requestLidoWithdrawal() external { }
    function test_claimLidoWithdrawals() external { }
    function test_setStakingManagerEth() external { }
    function test_setAutoStakeEth() external { }

    // ----------- Dai Strategy ------------
    function test_ownerDepositDai() external { }
    function test_ownerWithdrawDai() external { }
    function test_setStakingManagerDai() external { }
    function test_setAutoStakeDai() external { }
}

// // SPDX-License-Identifier: UNLICENSED
// pragma solidity >=0.8.23 <0.9.0;

// import "forge-std/src/Vm.sol";
// import { PRBTest } from "@prb/test/src/PRBTest.sol";
// import { console2 } from "forge-std/src/console2.sol";
// import { StdCheats } from "forge-std/src/StdCheats.sol";
// import { StdUtils } from "forge-std/src/StdUtils.sol";

// import { EdgelessDeposit } from "../src/EdgelessDeposit.sol";
// import { StakingManager } from "../src/StakingManager.sol";
// import { WrappedToken } from "../src/WrappedToken.sol";
// import { EthStrategy } from "../src/strategies/EthStrategy.sol";
// import { DaiStrategy } from "../src/strategies/DaiStrategy.sol";

// import { IDAI } from "../src/interfaces/IDAI.sol";
// import { IL1StandardBridge } from "../src/interfaces/IL1StandardBridge.sol";
// import { ILido } from "../src/interfaces/ILido.sol";
// import { IUSDT } from "../src/interfaces/IUSDT.sol";
// import { IUSDC } from "../src/interfaces/IUSDC.sol";
// import { IWithdrawalQueueERC721 } from "../src/interfaces/IWithdrawalQueueERC721.sol";
// import { IStakingStrategy } from "../src/interfaces/IStakingStrategy.sol";

// import { Permit, SigUtils } from "./SigUtils.sol";
// import { DeploymentUtils } from "./DeploymentUtils.sol";

// /// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
// /// https://book.getfoundry.sh/forge/writing-tests
// contract EdgelessDepositTest is PRBTest, StdCheats, StdUtils, DeploymentUtils {
//     using SigUtils for Permit;

//     EdgelessDeposit internal edgelessDeposit;
//     WrappedToken internal wrappedEth;
//     WrappedToken internal wrappedUSD;
//     IL1StandardBridge internal l1standardBridge;
//     StakingManager internal stakingManager;
//     IStakingStrategy internal ethStakingStrategy;
//     IStakingStrategy internal daiStakingStrategy;

//     address public constant STETH_WHALE = 0x5F6AE08B8AeB7078cf2F96AFb089D7c9f51DA47d; // Blast Deposits

//     uint32 public constant FORK_BLOCK_NUMBER = 18_950_000;

//     address public owner = makeAddr("Edgeless owner");
//     address public depositor = makeAddr("Depositor");
//     uint256 public depositorKey = uint256(keccak256(abi.encodePacked("Depositor")));
//     address public staker = makeAddr("Staker");

//     /// @dev A function invoked before each test case is run.
//     function setUp() public virtual {
//         string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
//         vm.createSelectFork({
//             urlOrAlias: string(abi.encodePacked("https://eth-mainnet.g.alchemy.com/v2/", alchemyApiKey)),
//             blockNumber: FORK_BLOCK_NUMBER
//         });

//         (stakingManager, edgelessDeposit, wrappedEth, wrappedUSD, ethStakingStrategy, daiStakingStrategy) =
//             deployContracts(owner, owner);
//     }

//     function test_EthMint(uint256 amount) external { }
//     function test_DAIMint(uint256 amount) external { }
//     function test_EthMintWithDeposit(uint256 amount) external { }
//     function test_DAIMintWithDeposit(uint256 amount) external { }
//     function test_LidoRequestWithdrawal(uint64 amount) external { }
//     function test_LidoClaimWithdrawal(uint64 amount) external { }
//     function test_setStakerWithPermission() external { }
//     function test_setStakerWithoutPermission() external { }
//     function test_setL1StandardBridgeWithPermission() external { }
//     function test_setL1StandardBridgeWithoutPermission() external { }
//     function test_setAutoBridgeWithPermission() external { }
//     function test_setAutoBridgeWithoutPermission() external { }
//     function test_setActiveStrategyWithPermission() external { }
//     function test_setActiveStrategyWithoutPermission() external { }
//     function test_setAutoStakeWithPermission() external { }
//     function test_setAutoStakeWithoutPermission() external { }
//     function test_setL2EthAsOwner() external { }
//     function test_setL2EthAsNonOwner() external { }
//     function test_upgradability() external { }

//     // TODO: Add more checks for all variables: sDAI balance, DAI balance, etc.
//     function depositAndWithdrawDAI(address depositor, address asset, uint256 amount) internal {
//         vm.startPrank(depositor);
//         // Deposit DAI
//         DAI.approve(address(edgelessDeposit), amount);
//         edgelessDeposit.depositDAI(depositor, amount);

//         // Withdraw DAI by burning wrapped stablecoin - sDAI rounds down, so you lose 2 wei worth of dai(not 2 dai)
//         edgelessDeposit.withdrawUSD(depositor, amount - 2);
//         assertAlmostEq(DAI.balanceOf(depositor), amount, 2, "Depositor should have `amount` of DAI afterwithdrawing");
//         assertAlmostEq(
//             wrappedUSD.balanceOf(depositor), 0, 2, "Depositor should have 0 wrapped stablecoin after withdrawing"
//         );
//         assertAlmostEq(DAI.balanceOf(address(edgelessDeposit)), 0, 2, "Edgeless should have 0 DAI afterwithdrawing");
//     }
// }

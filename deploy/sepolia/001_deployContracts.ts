import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import * as WrappedTokenArtifact from "../../artifacts/src/WrappedToken.sol/WrappedToken.json";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, get, getOrNull, log, read, save } = deployments;
  const { deployer, owner, staker, l1StandardBridge } =
    await getNamedAccounts();
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  const EdgelessDeposit = await getOrNull("EdgelessDeposit");
  if (!EdgelessDeposit) {
    await deploy("StakingManager", {
      from: deployer,
      proxy: {
        proxyContract: "UUPS",
        execute: {
          init: {
            methodName: "initialize",
            args: [owner, staker],
          },
        },
      },
      skipIfAlreadyDeployed: true,
      log: true,
    });

    if (
      (await read("StakingManager", "staker")) != staker ||
      (await read("StakingManager", "staker")) == ZERO_ADDRESS
    ) {
      throw new Error("StakingManager staker not set correctly");
    }

    if (
      (await read("StakingManager", "owner")) != staker ||
      (await read("StakingManager", "owner")) == ZERO_ADDRESS
    ) {
      throw new Error("StakingManager staker not set correctly");
    }

    await deploy("EdgelessDeposit", {
      from: deployer,
      proxy: {
        proxyContract: "UUPS",
        execute: {
          init: {
            methodName: "initialize",
            args: [
              owner,
              l1StandardBridge,
              (await get("StakingManager")).address,
            ],
          },
        },
      },
      skipIfAlreadyDeployed: true,
      log: true,
    });

    if (
      (await read("EdgelessDeposit", "owner")) != owner ||
      (await read("EdgelessDeposit", "owner")) == ZERO_ADDRESS
    ) {
      throw new Error("EdgelessDeposit owner not set correctly");
    }

    if (
      (await read("EdgelessDeposit", "l1standardBridge")) != l1StandardBridge ||
      (await read("EdgelessDeposit", "l1standardBridge")) == ZERO_ADDRESS
    ) {
      throw new Error("EdgelessDeposit l1standardBridge not set correctly");
    }

    if (
      (await read("EdgelessDeposit", "stakingManager")) !=
        (await get("StakingManager")).address ||
      (await read("EdgelessDeposit", "stakingManager")) == ZERO_ADDRESS
    ) {
      throw new Error("EdgelessDeposit stakingManager not set correctly");
    }

    if ((await read("EdgelessDeposit", "autoBridge")) == true) {
      throw new Error("EdgelessDeposit autoBridge not set correctly");
    }

    if ((await read("EdgelessDeposit", "wrappedEth")) == ZERO_ADDRESS) {
      throw new Error("EdgelessDeposit wrappedEth not set correctly");
    }

    if ((await read("EdgelessDeposit", "wrappedUSD")) == ZERO_ADDRESS) {
      throw new Error("EdgelessDeposit wrappedUSD not set correctly");
    }

    await save("Edgeless Wrapped ETH", {
      address: await read("EdgelessDeposit", "wrappedEth"),
      abi: WrappedTokenArtifact["abi"],
    });

    await save("Edgeless Wrapped USD", {
      address: await read("EdgelessDeposit", "wrappedUSD"),
      abi: WrappedTokenArtifact["abi"],
    });

    await execute(
      "StakingManager",
      { from: owner, log: true },
      "setStaker",
      (await get("EdgelessDeposit")).address,
    );

    await execute(
      "StakingManager",
      {
        from: owner,
        log: true,
      },
      "setDepositor",
      (await get("EdgelessDeposit")).address,
    );

    if (
      (await read("StakingManager", "staker")) !=
        (await get("EdgelessDeposit")).address ||
      (await read("StakingManager", "staker")) == ZERO_ADDRESS
    ) {
      throw new Error("StakingManager staker not set correctly");
    }

    if (
      (await read("StakingManager", "owner")) != owner ||
      (await read("StakingManager", "owner")) == ZERO_ADDRESS
    ) {
      throw new Error("StakingManager owner not set correctly");
    }

    if (
      (await read("StakingManager", "depositor")) !=
        (await get("EdgelessDeposit")).address ||
      (await read("StakingManager", "depositor")) == ZERO_ADDRESS
    ) {
      throw new Error("StakingManager depositor not set correctly");
    }

    await deploy("EthStrategy", {
      from: deployer,
      proxy: {
        proxyContract: "UUPS",
        execute: {
          init: {
            methodName: "initialize",
            args: [owner, (await get("StakingManager")).address],
          },
        },
      },
      skipIfAlreadyDeployed: true,
      log: true,
    });

    await execute(
      "EthStrategy",
      { from: owner, log: true },
      "setAutoStake",
      false,
    );

    await execute(
      "StakingManager",
      { from: owner, log: true },
      "addStrategy",
      await read("StakingManager", "ETH_ADDRESS"),
      (await get("EthStrategy")).address,
    );

    await execute(
      "StakingManager",
      { from: owner, log: true },
      "setActiveStrategy",
      await read("StakingManager", "ETH_ADDRESS"),
      0,
    );

    if (
      (await read("EthStrategy", "owner")) != owner ||
      (await read("EthStrategy", "owner")) == ZERO_ADDRESS
    ) {
      throw new Error("EthStrategy owner not set correctly");
    }

    if (
      (await read("EthStrategy", "stakingManager")) !=
        (await get("StakingManager")).address ||
      (await read("EthStrategy", "stakingManager")) == ZERO_ADDRESS
    ) {
      throw new Error("EthStrategy stakingManager not set correctly");
    }

    if ((await read("EthStrategy", "autoStake")) == true) {
      throw new Error("EthStrategy autoStake not set correctly");
    }

    if (
      (await read(
        "StakingManager",
        "getActiveStrategy",
        await read("EthStrategy", "underlyingAsset"),
      )) != (await get("EthStrategy")).address
    ) {
      throw new Error("StakingManager activeStrategy not set correctly");
    }

    await deploy("DaiStrategy", {
      from: deployer,
      proxy: {
        proxyContract: "UUPS",
        execute: {
          init: {
            methodName: "initialize",
            args: [owner, (await get("StakingManager")).address],
          },
        },
      },
      skipIfAlreadyDeployed: true,
      log: true,
    });

    await execute(
      "DaiStrategy",
      { from: owner, log: true },
      "setAutoStake",
      false,
    );

    await execute(
      "StakingManager",
      { from: owner, log: true },
      "addStrategy",
      await read("DaiStrategy", "underlyingAsset"),
      (await get("DaiStrategy")).address,
    );

    await execute(
      "StakingManager",
      { from: owner, log: true },
      "setActiveStrategy",
      await read("DaiStrategy", "underlyingAsset"),
      0,
    );

    if (
      (await read("DaiStrategy", "owner")) != owner ||
      (await read("DaiStrategy", "owner")) == ZERO_ADDRESS
    ) {
      throw new Error("DaiStrategy owner not set correctly");
    }

    if (
      (await read("DaiStrategy", "stakingManager")) !=
        (await get("StakingManager")).address ||
      (await read("DaiStrategy", "stakingManager")) == ZERO_ADDRESS
    ) {
      throw new Error("DaiStrategy stakingManager not set correctly");
    }

    if ((await read("DaiStrategy", "autoStake")) == true) {
      throw new Error("DaiStrategy autoStake not set correctly");
    }

    if (
      (await read(
        "StakingManager",
        "getActiveStrategy",
        await read("DaiStrategy", "underlyingAsset"),
      )) != (await get("DaiStrategy")).address
    ) {
      throw new Error("StakingManager activeStrategy not set correctly");
    }
  } else {
    log("EdgelessDeposit already deployed, skipping...");
  }
};
export default func;
// func.skip = async () => true;

import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import * as WrappedTokenArtifact from "../../artifacts/src/WrappedToken.sol/WrappedToken.json"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre
    const { get, getOrNull, read } = deployments

    // await hre.run("etherscan-verify", {
    //     apiKey: process.env.ETHERSCAN_API_KEY,
    // })

    await hre.run("verify:verify", {
        address: (await get("Edgeless Wrapped ETH")).address,
        constructorArguments: [
            (await get('EdgelessDeposit')).address,
            await read("Edgeless Wrapped ETH", "name"),
            await read("Edgeless Wrapped ETH", "symbol")
        ],
    });


    await hre.run("verify:verify", {
        address: (await get("Edgeless Wrapped USD")).address,
        constructorArguments: [
            (await get('EdgelessDeposit')).address,
            await read("Edgeless Wrapped USD", "name"),
            await read("Edgeless Wrapped USD", "symbol")
        ],
    });

};
export default func;

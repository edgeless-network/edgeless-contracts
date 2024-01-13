// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { LIDO, DAI, _RAY, DSR_MANAGER, LIDO_WITHDRAWAL_ERC721, ETH } from "../Constants.sol";

import { MakerMath } from "../lib/MakerMath.sol";

import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";
import { IPot } from "../interfaces/IPot.sol";

contract DaiStrategy is IStakingStrategy {
    function stake(uint256 amount) external payable {
        if (msg.value > 0) revert IncorrectFunds();
        if (amount > DAI.balanceOf(address(this))) {
            revert InsufficientFunds();
        }

        DAI.approve(address(DSR_MANAGER), amount);
        DSR_MANAGER.join(address(this), amount);
        emit Staked(amount);
    }

    function withdraw(uint256 amount) external {
        if (amount > DSR_MANAGER.daiBalance(address(this))) {
            revert InsufficientFunds();
        }

        DSR_MANAGER.exit(msg.sender, amount);
    }

    /**
     * @notice Get the current ETH pool balance
     * @return Pooled ETH balance between buffered balance and deposited Lido balance
     */
    function totalETHBalance() public pure returns (uint256) {
        return 0;
    }

    /**
     * @notice Get the current USD pool balance
     * @dev Does not update DSR yield
     * @return Pooled USD balance between buffered balance and deposited DSR balance
     */
    function totalUSDBalanceNoUpdate() public view returns (uint256) {
        IPot pot = DSR_MANAGER.pot();
        uint256 chi = MakerMath.rmul(MakerMath.rpow(pot.dsr(), block.timestamp - pot.rho(), _RAY), pot.chi());
        return DAI.balanceOf(address(this)) + MakerMath.rmul(DSR_MANAGER.pieOf(address(this)), chi);
    }

    /**
     * @notice Get the current USD pool balance
     * @return Pooled USD balance between buffered balance and deposited DSR balance
     */
    function totalUSDBalance() public returns (uint256) {
        return DAI.balanceOf(address(this)) + DSR_MANAGER.daiBalance(address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { LIDO, DAI, _RAY, DSR_MANAGER, LIDO_WITHDRAWAL_ERC721, ETH } from "./Constants.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IStakingStrategy } from "./interfaces/IStakingStrategy.sol";

/**
 * @title StakingManager
 * @notice Manages staking of pooled funds, the goal is to maintain the minimum amount of ETH
 * and DAI so users can withdraw their funds without delay, while maximizing the staking yield.
 */
contract StakingManager is Ownable2Step {
    bool public autoStake;
    address public staker;

    uint40 public ethStrategyIndex;
    uint40 public daiStrategyIndex;

    IStakingStrategy[] public ethStrategies;
    IStakingStrategy[] public daiStrategies;

    event SetAutoStake(bool autoDeposit);
    event SetDaiStratgyIndex(uint40 _daiStrategyIndex);
    event SetDaiStratgeyAtIndex(IStakingStrategy indexed _daiStrategy, uint40 _daiStrategyIndex);
    event SetEthStratgyIndex(uint40 _ethStrategyIndex);
    event SetEthStratgyAtIndex(IStakingStrategy indexed _ethStrategy, uint40 _ethStrategyIndex);
    event SetStaker(address staker);

    error InsufficientFunds();
    error SenderIsNotStaker();
    error UnsupportedToken(address token);

    modifier onlyStaker() {
        if (msg.sender != staker) revert SenderIsNotStaker();
        _;
    }

    constructor(address _staker, address _owner) Ownable(_owner) {
        _setStaker(_staker);
    }

    /// -------------------------------- 📝 External Functions 📝 --------------------------------

    function stakeToken(address token, uint256 amount) external payable {
        if (token == address(DAI)) {
            _stakeDAI(amount);
        } else if (token == ETH) {
            _stakeETH(msg.value);
        } else {
            revert UnsupportedToken(token);
        }
    }

    function withdrawDai(uint256 amount) external { }

    function totalETHBalance() external view returns (uint256 balance) {
        for (uint256 i = 0; i < ethStrategies.length; i++) {
            balance += ethStrategies[i].totalETHBalance();
        }
    }

    function totalUSDBalanceNoUpdate() external view returns (uint256 balance) {
        for (uint256 i = 0; i < daiStrategies.length; i++) {
            balance += daiStrategies[i].totalUSDBalanceNoUpdate();
        }
    }

    function totalUSDBalance() external returns (uint256 balance) {
        for (uint256 i = 0; i < daiStrategies.length; i++) {
            balance += daiStrategies[i].totalUSDBalance();
        }
    }

    /// ---------------------------------- 🔓 Admin Functions 🔓 ----------------------------------
    /**
     * @notice Only the owner of EdgelessDeposit can set the staker address
     */
    function setStaker(address _staker) external onlyOwner {
        _setStaker(_staker);
    }

    /**
     * @notice Set autoStake to true so all deposits sent to this contract will be staked.
     */
    function setAutoStake(bool _autoStake) public onlyStaker {
        _setAutoStake(_autoStake);
    }

    /**
     * @notice The staker can manually stake `amount` of DAI into the Maker DSR
     */
    function stakeDAI(uint256 amount) external onlyStaker {
        _stakeDAI(amount);
    }
    /**
     * @notice The staker can manually stake `amount` of ETH into Lido
     */

    function stakeETH(uint256 amount) external onlyStaker {
        _stakeETH(amount);
    }

    function setEthStratgyIndex(uint40 _ethStrategyIndex) external onlyStaker {
        ethStrategyIndex = _ethStrategyIndex;
        emit SetEthStratgyIndex(_ethStrategyIndex);
    }

    function setDaiStratgyIndex(uint40 _daiStrategyIndex) external onlyStaker {
        daiStrategyIndex = _daiStrategyIndex;
        emit SetDaiStratgyIndex(_daiStrategyIndex);
    }

    function setDaiStratgeyAtIndex(IStakingStrategy _daiStrategy, uint40 _daiStrategyIndex) external onlyStaker {
        if (_daiStrategyIndex == daiStrategies.length) {
            daiStrategies.push(_daiStrategy);
        } else {
            daiStrategies[_daiStrategyIndex] = _daiStrategy;
        }
        emit SetDaiStratgeyAtIndex(_daiStrategy, _daiStrategyIndex);
    }

    function setEthStratgeyAtIndex(IStakingStrategy _ethStrategy, uint40 _ethStrategyIndex) external onlyStaker {
        if (_ethStrategyIndex == ethStrategies.length) {
            ethStrategies.push(_ethStrategy);
        } else {
            ethStrategies[_ethStrategyIndex] = _ethStrategy;
        }
        emit SetEthStratgyAtIndex(_ethStrategy, _ethStrategyIndex);
    }

    /// -------------------------------- 🏗️ Internal Functions 🏗️ --------------------------------

    function _setStaker(address _staker) internal {
        staker = _staker;
        emit SetStaker(_staker);
    }

    /**
     * @notice Stake pooled USD funds by depositing DAI into the Maker DSR
     * @param amount Amount in DAI to stake (usd)
     */
    function _stakeDAI(uint256 amount) internal {
        IStakingStrategy daiStrategy = daiStrategies[daiStrategyIndex];
        DAI.transfer(address(daiStrategy), amount);
        daiStrategy.stake(amount);
    }

    /**
     * @notice Stake pooled ETH funds by submiting ETH to Lido
     * @param amount Amount in ETH to stake (wad)
     */
    function _stakeETH(uint256 amount) internal {
        ethStrategies[ethStrategyIndex].stake{ value: amount }(0);
    }

    function _setAutoStake(bool _autoStake) internal {
        autoStake = _autoStake;
        emit SetAutoStake(_autoStake);
    }
}

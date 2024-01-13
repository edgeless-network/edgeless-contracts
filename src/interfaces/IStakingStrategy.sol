// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

interface IStakingStrategy {
    event Staked(uint256 amount);

    error InsufficientFunds();
    error IncorrectFunds();

    function stake(uint256 amount) external payable;
    function withdraw(uint256 amount) external;

    function totalETHBalance() external view returns (uint256);
    function totalUSDBalanceNoUpdate() external view returns (uint256);
    function totalUSDBalance() external returns (uint256);
}

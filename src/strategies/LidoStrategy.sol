// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { LIDO, LIDO_WITHDRAWAL_ERC721 } from "../Constants.sol";

import { IStakingStrategy } from "../interfaces/IStakingStrategy.sol";

contract LidoStrategy is IStakingStrategy {
    event ClaimedLidoWithdrawals(uint256[] requestIds);
    event RequestedLidoWithdrawals(uint256[] requestIds, uint256[] amounts);

    receive() external payable { }

    function stake(uint256) external payable {
        if (msg.value == 0) revert InsufficientFunds();
        LIDO.submit{ value: msg.value }(address(0));
        emit Staked(msg.value);
    }

    function withdraw(uint256 amount) external {
        if (amount > address(this).balance) revert InsufficientFunds();
        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Get the current ETH pool balance
     * @return Pooled ETH balance between buffered balance and deposited Lido balance
     */
    function totalETHBalance() public view returns (uint256) {
        return address(this).balance + LIDO.balanceOf(address(this));
    }

    /**
     * @notice Get the current USD pool balance
     * @dev Does not update DSR yield
     * @return Pooled USD balance between buffered balance and deposited DSR balance
     */
    function totalUSDBalanceNoUpdate() public pure returns (uint256) {
        return 0;
    }

    /**
     * @notice Get the current USD pool balance
     * @return Pooled USD balance between buffered balance and deposited DSR balance
     */
    function totalUSDBalance() public pure returns (uint256) {
        return 0;
    }

    function requestLidoWithdrawal(uint256[] calldata amount) external returns (uint256[] memory requestIds) {
        uint256 total = 0;
        for (uint256 i = 0; i < amount.length; i++) {
            total += amount[i];
        }
        LIDO.approve(address(LIDO_WITHDRAWAL_ERC721), total);
        requestIds = LIDO_WITHDRAWAL_ERC721.requestWithdrawals(amount, address(this));
        emit RequestedLidoWithdrawals(requestIds, amount);
    }

    function claimLidoWithdrawals(uint256[] calldata requestIds) external {
        uint256 lastCheckpointIndex = LIDO_WITHDRAWAL_ERC721.getLastCheckpointIndex();
        uint256[] memory _hints = LIDO_WITHDRAWAL_ERC721.findCheckpointHints(requestIds, 1, lastCheckpointIndex);
        LIDO_WITHDRAWAL_ERC721.claimWithdrawals(requestIds, _hints);
        emit ClaimedLidoWithdrawals(requestIds);
    }
}

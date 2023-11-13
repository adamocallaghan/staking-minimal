// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";

contract Staking is ERC20, ReentrancyGuard {
    // Owner
    address public owner;

    // Staking Token
    IERC20 public stakingToken;
    uint256 public immutable i_rewardsPerSecond = 1;

    // Balances
    mapping(address => uint256) public balances;
    mapping(address => uint256) public timestamps;

    // Errors
    error Error__NotCorrectStakingToken();
    error Error__UserHasInsufficientBalanceOfStakingToken();
    error Error__UserHasInsufficientTokensStaked();

    // Events
    event tokensStaked(address from, uint256 amount);
    event tokensUnstaked(address to, uint256 amount);

    constructor(IERC20 _stakingToken) ERC20("RewardsTokens", "RWRD") {
        owner = msg.sender;
        stakingToken = _stakingToken;
    }

    function stake(IERC20 _token, uint256 _amount) public nonReentrant {
        // check that the token is the corrct stakingToken
        if (_token != stakingToken) {
            revert Error__NotCorrectStakingToken();
        }

        // check that the user has enough stakingToken balance to stake
        if (_amount > _token.balanceOf(msg.sender)) {
            revert Error__UserHasInsufficientBalanceOfStakingToken();
        }

        // transfer tokens to contract
        _token.transferFrom(msg.sender, address(this), _amount);

        // update timestamps
        timestamps[msg.sender] = block.timestamp;

        // update balances
        balances[msg.sender] = balances[msg.sender] + _amount;

        // emit event
        emit tokensStaked(msg.sender, _amount);
    }

    function unstake(IERC20 _token, uint256 _amount) public nonReentrant {
        // check that the token is the corrct stakingToken
        if (_token != stakingToken) {
            revert Error__NotCorrectStakingToken();
        }

        if (balances[msg.sender] < _amount) {
            revert Error__UserHasInsufficientTokensStaked();
        }

        // update balances
        balances[msg.sender] = balances[msg.sender] - _amount;

        // transfer tokens back to user
        _token.transfer(msg.sender, _amount);

        // emit event
        emit tokensUnstaked(msg.sender, _amount);

        // get rewards
        getRewards();
    }

    function getRewards() internal {
        // get amount of seconds user has staked for
        uint256 stakingTimeInSeconds = block.timestamp - timestamps[msg.sender];

        // calculate rewards
        uint256 userRewards = stakingTimeInSeconds * i_rewardsPerSecond;

        // issue rewards
        _mint(msg.sender, userRewards);
    }
}

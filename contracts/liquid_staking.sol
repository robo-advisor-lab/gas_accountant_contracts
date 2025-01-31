// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidStaking is ERC20, Ownable {
    uint256 public lastRewardTime; // Tracks last reward distribution
    uint256 public constant APY = 4; // 4% Annual Percentage Yield
    uint256 public constant SECONDS_IN_YEAR = 365 days;

    uint256 public rewardPerTokenStored; // Accumulated reward per stETH
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    constructor(address initialOwner) ERC20("Staked Sepolia ETH", "stETH") Ownable(initialOwner) {
        lastRewardTime = block.timestamp; // Initialize reward timer
    }

    // 📌 Modifier: Auto-Update Rewards Before Any Action
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastRewardTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // 📌 Users stake ETH & receive stETH (Auto-Updates Rewards)
    function stake() external payable updateReward(msg.sender) {
        require(msg.value > 0, "Must send ETH");

        uint256 shares = msg.value; // 1:1 ETH to stETH ratio (before rewards)
        _mint(msg.sender, shares);
    }

    // 📌 Users unstake stETH for ETH (Auto-Updates Rewards)
    function unstake(uint256 _amount) external updateReward(msg.sender) {
        require(balanceOf(msg.sender) >= _amount, "Not enough stETH");

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
    }

    // 📌 View: Calculate Reward Per Token
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }

        uint256 timeElapsed = block.timestamp - lastRewardTime;
        uint256 totalRewards = (totalSupply() * APY * timeElapsed) / (100 * SECONDS_IN_YEAR);
        return rewardPerTokenStored + (totalRewards * 1e18) / totalSupply();
    }

    // 📌 View: Get User's Earned Rewards
    function earned(address account) public view returns (uint256) {
        return ((balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    // 📌 Users Claim Accumulated Staking Rewards (Auto-Updates Rewards)
    function claimRewards() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        _mint(msg.sender, reward); // Mint rewards directly to user

        emit ClaimRewards(msg.sender, reward);
    }

    // 📌 Allows contract to receive ETH
    receive() external payable {}

    // 📌 Allow admin to withdraw any ETH in case of emergency
    function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Not enough ETH");
        payable(owner()).transfer(_amount);
    }

    // 📌 Events
    event ClaimRewards(address indexed user, uint256 amount);
}

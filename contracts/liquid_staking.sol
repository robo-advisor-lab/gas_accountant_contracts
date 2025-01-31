// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidStaking is ERC20 {
    address public yieldFarm; // Yield farm where ETH is deployed
    uint256 public lastRewardTime; // Tracks last reward distribution
    uint256 public constant APY = 4; // 4% Annual Percentage Yield
    uint256 public constant SECONDS_IN_YEAR = 365 days;

    constructor(address _yieldFarm) ERC20("Staked Sepolia ETH", "stETH") {
        yieldFarm = _yieldFarm;
        lastRewardTime = block.timestamp; // Initialize reward timer
    }

    // Users stake ETH & receive stETH
    function stake() external payable {
        require(msg.value > 0, "Must send ETH");

        uint256 shares = msg.value; // 1:1 ETH to stETH ratio (before rewards)
        _mint(msg.sender, shares);

        // Send ETH to the yield farm (simulate staking)
        payable(yieldFarm).transfer(msg.value);
    }

    // Users unstake stETH for ETH
    function unstake(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Not enough stETH");

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
    }

    // 📌 New function: Distribute 4% APY as staking rewards
    function distributeRewards() external {
        uint256 timeElapsed = block.timestamp - lastRewardTime;
        require(timeElapsed > 0, "Rewards already distributed");

        // Calculate staking rewards: (total stETH supply * 4% APY * time elapsed)
        uint256 totalStaked = totalSupply();
        uint256 rewardAmount = (totalStaked * APY * timeElapsed) / (100 * SECONDS_IN_YEAR);
        
        if (rewardAmount > 0) {
            _mint(yieldFarm, rewardAmount); // Mint rewards to Yield Farm (for reinvestment)
        }

        lastRewardTime = block.timestamp; // Update reward time
    }

    // Allows anyone to send ETH to the contract
    receive() external payable {}
}

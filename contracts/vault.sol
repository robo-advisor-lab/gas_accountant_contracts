// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGasReserve {
    function requestGas(uint256 _amount) external;
}

interface ILiquidStaking {
    function claimRewards() external;
    function stake() external payable;
}

contract YieldVault is ERC20, Ownable {
    IERC20 public stETH;  // Reference to stETH (LiquidStaking contract)
    IGasReserve public gasReserve;

    uint256 public lastHarvestTime;
    uint256 public totalRewardsDistributed; // Tracks total earned rewards

    constructor(address _liquidStaking, address _gasReserve)
        ERC20("Yield Vault Staked ETH", "yvSTETH")
        Ownable(msg.sender)
    {
        stETH = IERC20(_liquidStaking); // Assign stETH to the LiquidStaking contract
        gasReserve = IGasReserve(_gasReserve);
        lastHarvestTime = block.timestamp;
    }

    // 📌 Users deposit Sepolia ETH → Vault stakes into Liquid Staking → Mints yvSTETH
    function deposit() external payable {
        require(msg.value > 0, "Must deposit ETH");

        // Stake ETH into Liquid Staking contract (which is also the stETH contract)
        ILiquidStaking(address(stETH)).stake{value: msg.value}();

        // Get stETH balance after staking
        uint256 stETHBalance = stETH.balanceOf(address(this));

        // Mint yvSTETH to user
        _mint(msg.sender, stETHBalance);
    }

    // 📌 Users withdraw by burning yvSTETH & receiving their share of stETH
    function withdraw(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Not enough yvSTETH");

        uint256 totalSupplyVault = totalSupply();
        uint256 vaultBalance = stETH.balanceOf(address(this));

        // Calculate the user's share of stETH, including rewards
        uint256 userShare = (vaultBalance * _amount) / totalSupplyVault;

        _burn(msg.sender, _amount); // Burn user's yvSTETH
        stETH.transfer(msg.sender, userShare); // Transfer stETH to user
    }

    // 📌 Manual Harvest by Owner (Gas Reserve Pays) - NO time restriction
    function harvest() external onlyOwner {
        // Request gas from Gas Reserve before harvesting
        gasReserve.requestGas(0.01 ether);

        // Claim rewards from Liquid Staking contract (which is also stETH)
        uint256 preBalance = stETH.balanceOf(address(this)); // Track balance before claim
        ILiquidStaking(address(stETH)).claimRewards();
        uint256 postBalance = stETH.balanceOf(address(this)); // Track balance after claim

        // Calculate how much stETH was earned
        uint256 earnedRewards = postBalance - preBalance;
        totalRewardsDistributed += earnedRewards; // Track total rewards for monitoring

        lastHarvestTime = block.timestamp; // Update last harvest time
    }

    // 📌 View function: Get a user's share of stETH, including rewards
    function earned(address user) external view returns (uint256) {
        uint256 totalSupplyVault = totalSupply();
        uint256 vaultBalance = stETH.balanceOf(address(this));
        uint256 userShare = (vaultBalance * balanceOf(user)) / totalSupplyVault;
        return userShare;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldVault is ERC20 {
    IERC20 public stETH;  // Reference to Lido-style stETH
    address public strategy;  // Strategy contract for yield farming

    constructor(address _stETH, address _strategy)
        ERC20("Yield Vault Staked ETH", "yvSTETH")
    {
        stETH = IERC20(_stETH);
        strategy = _strategy;
    }

    // Deposit stETH & mint yvSTETH
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Must deposit stETH");

        stETH.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount); // 1:1 for simplicity

        // Deploy stETH into the strategy for farming
        stETH.transfer(strategy, _amount);
    }

    // Withdraw stETH
    function withdraw(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Not enough yvSTETH");

        _burn(msg.sender, _amount);
        stETH.transfer(msg.sender, _amount); // Return stETH to user
    }

    // Harvest & auto-compound yield
    function harvest() external {
        (bool success, ) = strategy.call(abi.encodeWithSignature("claimRewards()"));
        require(success, "Harvest failed");
    }
}

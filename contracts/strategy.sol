// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StETHStrategy {
    IERC20 public stETH;
    address public vault;
    address public farmingPool; // A yield farm that accepts stETH
    address public gasReserve; // Gas reserve contract

    constructor(address _stETH, address _vault, address _farmingPool, address _gasReserve) {
        stETH = IERC20(_stETH);
        vault = _vault;
        farmingPool = _farmingPool;
        gasReserve = _gasReserve;
    }

    // 📌 Deposit stETH into a farming protocol
    function deposit(uint256 _amount) external {
        require(msg.sender == vault, "Only vault");
        require(_amount > 0, "Must deposit stETH");

        stETH.transfer(farmingPool, _amount);
    }

    // 📌 Claim yield & reinvest into stETH
    function claimRewards() external {
        // 📌 Request ETH for gas from the Gas Reserve
        (bool gasSuccess, ) = gasReserve.call(abi.encodeWithSignature("requestGas(uint256)", 0.01 ether));
        require(gasSuccess, "Gas request failed");

        // 📌 Call farming contract to distribute rewards
        (bool success, ) = farmingPool.call(abi.encodeWithSignature("distributeRewards()"));
        require(success, "Claim failed");

        uint256 earned = address(this).balance;
        if (earned > 0) {
            payable(vault).transfer(earned); // Send new yield back to vault
        }
    }

    receive() external payable {}
}

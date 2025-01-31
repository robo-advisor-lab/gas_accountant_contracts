// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GasReserve {
    address public admin;
    mapping(address => bool) public authorizedContracts;

    // 📌 Event to log gas requests
    event GasRequested(uint256 timestamp, address indexed requester, uint256 amount);

    constructor() {
        admin = msg.sender; // Deployer is admin
    }

    // 📌 Fund the gas reserve with ETH
    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
    }

    // 📌 Whitelist Vault & Strategy contracts to use gas
    function authorizeContract(address _contract) external {
        require(msg.sender == admin, "Only admin");
        authorizedContracts[_contract] = true;
    }

    // 📌 Remove authorization (in case of upgrades)
    function deauthorizeContract(address _contract) external {
        require(msg.sender == admin, "Only admin");
        authorizedContracts[_contract] = false;
    }

    // 📌 Allow whitelisted contracts to request ETH for gas fees
    function requestGas(uint256 _amount) external {
        require(authorizedContracts[msg.sender], "Not authorized");
        require(address(this).balance >= _amount, "Not enough gas reserve");

        payable(msg.sender).transfer(_amount);

        // 📌 Log the gas request
        emit GasRequested(block.timestamp, msg.sender, _amount);
    }

    // 📌 Emergency withdraw (Admin only)
    function emergencyWithdraw(uint256 _amount) external {
        require(msg.sender == admin, "Only admin");
        payable(admin).transfer(_amount);
    }
}

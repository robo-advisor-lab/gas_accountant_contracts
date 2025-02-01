// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract BatchTransfer {
    function batchSendETH(address[] calldata recipients, uint256[] calldata amounts) external payable {
        require(recipients.length == amounts.length, "Mismatched arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amounts[i]);
        }
    }
}

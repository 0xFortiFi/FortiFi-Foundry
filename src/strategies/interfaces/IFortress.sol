// SPDX-License-Identifier: GPL-3.0-only
// IFortress Interface by FortiFi

pragma solidity 0.8.21;

/// @title Interface for FortiFi Fortresses
interface IFortress {
    function deposit(uint amount, address user) external returns(uint);
    function withdraw(address user, address[] memory extraTokens) external;
    function withdrawBricked(address user) external;
    function recoverERC20(address to, address token, uint amount) external;
    function balanceOf(address holder) external view returns(uint256);
}
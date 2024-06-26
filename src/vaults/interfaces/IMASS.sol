// SPDX-License-Identifier: GPL-3.0-only
// IMASS Interface by FortiFi

pragma solidity 0.8.21;

/// @title Interface for FortiFi MASS Vaults
interface IMASS {
    struct Strategy {
        address strategy;
        address depositToken;
        address router;
        address oracle;
        bool isFortiFi;
        bool isSAMS;
        uint16 bps;
        uint8 decimals;
    }

    struct Position {
        Strategy strategy;
        uint256 receipt;
    }

    struct TokenInfo {
        uint256 deposit;
        Position[] positions;
    }

    function deposit(uint amount) external returns(uint256 tokenId, TokenInfo memory info);
    function add(uint amount, uint tokenId) external returns(TokenInfo memory info);
    function withdraw(uint amount) external;
    function rebalance(uint tokenId) external returns(TokenInfo memory info);
    function getStrategies() external view returns(Strategy[] memory strategies);
}
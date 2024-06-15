// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";
import {FortiFiFeeManager} from "../src/fee-managers/FortiFiFeeManager.sol";

contract FortiFiFeeManagerTest is Test {
    FortiFiFeeManager public feeMgr;
    MockERC20 public token;

    address public feeAddress = 0xa79dF98FB95b0392a045d2B93B76DE9e28a8dA88;

    function setUp() public {
        address[] memory feeArray = new address[](1);
        feeArray[0] = feeAddress;

        uint16[] memory feeBps = new uint16[](1);
        feeBps[0] = 10000;

        feeMgr = new FortiFiFeeManager(feeArray, feeBps);
        token = new MockERC20();
    }

    function test_TokensMinted() public {
        assertEq(token.balanceOf(address(this)), 80000000 ether);
    }

    function testFuzz_CollectFees(uint32 x) public {
        token.approve(address(feeMgr), x);
        feeMgr.collectFees(address(token), x);

        // if amount is greater than 10000 fees will be sent to feeAddress, otherwise they remain in contract
        if (x >= 1000) {
            assertEq(token.balanceOf(feeAddress), x);
        } else {
            assertEq(token.balanceOf(address(feeMgr)), x);
        }
    }
}

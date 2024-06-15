pragma solidity ^0.8.21;

// utilities
import {Test,console2} from "forge-std/Test.sol";

interface IGLPRewardRouter {
    function glpManager() external view returns(address);
}

interface IGLPManager {
    function getPrice(bool _maximise) external view returns (uint256);
}

// Test to show defect in GLP slippage calculation and a solution to resolve the issue
contract SlippageTest is Test {

    string AVALANCHE_RPC_URL = 'https://api.avax.network/ext/bc/C/rpc';
    uint256 avalancheFork;
    uint256 recentBlock = 44692480;

    function setUp() public {
        avalancheFork = vm.createFork(AVALANCHE_RPC_URL, recentBlock);
        vm.selectFork(avalancheFork);
    }

    // Current implementation of bad logic in src/strategies/FortiFiGLPFortress deposit function
    function testGlpSlippage() public {

        address rewardRouterAddress = 0xB70B91CE0771d3f4c81D87660f71Da31d48eB3B3;
        IGLPRewardRouter rewardRouter = IGLPRewardRouter(rewardRouterAddress);

        uint256 _glpPrice = IGLPManager(rewardRouter.glpManager()).getPrice(true);

        uint256 _amount = 1_000 * 1e6; // precision for usdc
        uint256 _glpOut = _amount * (10**18) / _glpPrice*10**(30 - 6); // GLP decimals are 18, price precision is 30 - 6 (USDC decimals)
        uint256 test = _glpOut * 9900 / 10000;

        console2.log(_glpOut); // this will be 0

        assertEq(_glpOut,0);

    }

    // Current implementation in withdraw function is OK
    function testGlpSlippageOut() public {

        address rewardRouterAddress = 0xB70B91CE0771d3f4c81D87660f71Da31d48eB3B3;
        IGLPRewardRouter rewardRouter = IGLPRewardRouter(rewardRouterAddress);

        uint256 _glpPrice = IGLPManager(rewardRouter.glpManager()).getPrice(true);

        uint256 _amount = 1_000 * 1e18; // precision for glp
        uint256 _glpOut = _amount * (_glpPrice / 10**18) / 10**(30 - 6);

        console2.log(_glpOut); // this will be greater than 0

        assertGt(_glpOut,0);

    }

    // Fix logic for deposit function to effectively calculate _glpOut
    function testGlpSlippageFixed() public {

        address rewardRouterAddress = 0xB70B91CE0771d3f4c81D87660f71Da31d48eB3B3;
        IGLPRewardRouter rewardRouter = IGLPRewardRouter(rewardRouterAddress);

        uint256 _glpPrice = IGLPManager(rewardRouter.glpManager()).getPrice(true);

        uint256 _amount = 1_000 * 1e6; // precision for usdc
        uint256 _glpOut = _amount * 10**30 / _glpPrice * 10**12; // GLP price decimals are 30, GLP decimals 18 - 6 (USDC decimals) = 12  

        console2.log(_glpOut); // this will be greater than 0

        assertGt(_glpOut,0);

    }

}
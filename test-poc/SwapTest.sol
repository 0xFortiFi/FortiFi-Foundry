pragma solidity ^0.8.21;

// utilities
import {Test,console2} from "forge-std/Test.sol";

// Test to show defect in swap slippage calculation and a solution to resolve the issue
contract SlippageTest is Test {

    function setUp() public {
    }

    // FUZZ TESTS TO SHOW CURRENT GOOD AND BAD LOGIC

    // Current implementation of bad logic in src/vaults/FortiFiMassVaultV2 _swapToDepositToken and _swapToDepositTokenDirect functions.
    // Problem occurs when _strat.decimals (_stratDecimals) is greater than 7.
    function testFuzz_SwapSlippage(uint8 _stratDecimals) public {
        vm.assume(_stratDecimals > 7 && _stratDecimals <= 18);

        uint256 _amount = 1_000e6;
        uint8 USDC_DECIMALS = 6;
        uint256 _latestPrice = 99985000;

        uint256 _swapAmount = _amount * (_latestPrice / 10**_stratDecimals) / 10**(8 - USDC_DECIMALS);

        assertEq(_swapAmount,0);

    }

    // Current implementation of bad logic in src/vaults/FortiFiMassVaultV2 _swapToDepositToken and _swapToDepositTokenDirect functions.
    // Problem does not occur when _strat.decimals (_stratDecimals) 6 or 7.
    function testFuzz_SwapSlippage2(uint8 _stratDecimals) public {
        vm.assume(_stratDecimals == 6 || _stratDecimals == 7);

        uint256 _amount = 1_000e6;
        uint8 USDC_DECIMALS = 6;
        uint256 _latestPrice = 99985000;

        uint256 _swapAmount = _amount * (_latestPrice / 10**_stratDecimals) / 10**(8 - USDC_DECIMALS);

        assertGt(_swapAmount,0);

    }

    // Current implementation of bad logic in src/vaults/FortiFiWNativeMassVaultV2 _swapToDepositTokenDirect functions.
    // Problem occurs when _amount is sufficiently small.
    function testFuzz_WNativeSwapSlippageAmount(uint80 _amount) public {
        vm.assume(_amount > 0 && _amount < 0.96 ether);

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;
        uint256 _latestPriceNative = 2541977100;
        uint256 _latestPriceTokenB = 2641977100;

        uint256 _swapAmount = _amount * _latestPriceTokenB / 10**18 / _latestPriceNative * 10**18 * 10**(WNATIVE_DECIMALS - _stratDecimals);

        assertEq(_swapAmount,0); // this is 0

    }

    // Current implementation of bad logic in src/vaults/FortiFiWNativeMassVaultV2 _swapToDepositTokenDirect functions.
    // Problem does not occur when _amount is sufficiently large.
    function testFuzz_WNativeSwapSlippageAmount2(uint80 _amount, uint56 _latestPriceNative, uint56 _latestPriceTokenB) public {
        vm.assume(
            _amount > 1 ether && 
            _amount < 1_000_000 ether &&
            _latestPriceNative > 0 &&
            _latestPriceTokenB > 0 &&
            _latestPriceNative < 1_000_000 * 10**8 &&
            _latestPriceTokenB < 1_000_000 * 10**8 &&
            _latestPriceNative <= _latestPriceTokenB
        );

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;

        uint256 _swapAmount = uint256(_amount) * uint256(_latestPriceTokenB) / 10**18 / uint256(_latestPriceNative) * 10**18 * 10**(WNATIVE_DECIMALS - _stratDecimals);

        assertGt(_swapAmount,0); // this is calculated correctly as greater than 0
    }


    // Current implementation of bad logic in src/vaults/FortiFiWNativeMassVaultV2 _swapToDepositTokenDirect functions.
    // Problem occurs when _latestPriceTokenB is too low relative to native token price
    function testFuzz_WNativeSwapSlippagePrice(uint80 _amount) public {
        vm.assume(
            _amount > 1 ether && 
            _amount < 1_000_000 ether 
        );

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;

        uint256 _latestPriceNative = 2541977100;
        uint256 _latestPriceTokenB = 2500;

        uint256 _swapAmount = uint256(_amount) * uint256(_latestPriceTokenB) / 10**18 / uint256(_latestPriceNative) * 10**18 * 10**(WNATIVE_DECIMALS - _stratDecimals);

        assertEq(_swapAmount,0);

    }

    // Current implementation of bad logic in src/vaults/FortiFiWNativeMassVaultV2 _swapToDepositTokenDirect functions.
    // Problem does not occur when _latestPriceTokenB is greater than or equal to native token price
    function testFuzz_WNativeSwapSlippagePrice2(uint80 _amount, uint56 _latestPriceNative, uint56 _latestPriceTokenB) public {
        vm.assume(
            _amount > 1 ether && 
            _amount < 1_000_000 ether &&
            _latestPriceNative > 1000 &&
            _latestPriceTokenB > 10000 &&
            _latestPriceNative < 10_000_000 * 10**8 &&
            _latestPriceTokenB < 10_000_000 * 10**8 &&
            _latestPriceNative <= _latestPriceTokenB
        );

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;

        uint256 _swapAmount = uint256(_amount) * uint256(_latestPriceTokenB) / 10**18 / uint256(_latestPriceNative) * 10**18 * 10**(WNATIVE_DECIMALS - _stratDecimals);

        console2.log(_swapAmount); // this is greater than 0
        assertGt(_swapAmount,0);

    }

    // FUZZ TESTS SHOWING SWAP OUT LOGIC WORKS

    // Current implementation in _swapFromDepositToken and _swapFromDepositTokenDirect in FortiFiMassVaultV2
    function testFuzz_testSwapSlippageOut(uint80 _amount) public {
        vm.assume(_amount > 10_000 && _amount < 1_000_000_000 * 10**6); 

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 USDC_DECIMALS = 6;
        uint256 _latestPrice = 99985000;

        uint256 _swapAmount = _amount * (10**_stratDecimals) / _latestPrice*10**(8 - USDC_DECIMALS);

        console2.log(_swapAmount); // Number is correctly calculated
        assertGt(_swapAmount,0);

    }

    // Current implementation in _swapFromDepositToken and _swapFromDepositTokenDirect FortiFiWNativeMassVaultV2
    function testFuzz_WNativeSwapSlippageOut(uint80 _amount, uint56 _latestPriceNative, uint56 _latestPriceTokenB) public {
        vm.assume(
            _amount > 1 ether && 
            _amount < 1_000_000 ether &&
            _latestPriceNative > 0 &&
            _latestPriceTokenB > 0 &&
            _latestPriceNative < 10_000_000 * 10**8 &&
            _latestPriceTokenB < 10_000_000 * 10**8 &&
            _latestPriceNative <= _latestPriceTokenB
        ); 

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;

        uint256 _swapAmount = uint256(_amount) * uint256(_latestPriceNative) * 10**18 / uint256(_latestPriceTokenB) / 10**18 / 10**(WNATIVE_DECIMALS - _stratDecimals);

        assertGt(_swapAmount,0);

    }

    // FIXES

    // Fix made so _swapAmount is greater than 0.
    // This test shows swapping to a token with 18 decimals (like wavax) works
    function test_SwapSlippageFix() public {
        //vm.assume(_stratDecimals > 7 && _stratDecimals <= 18);
        uint8 _stratDecimals = 18;    
        uint256 _amount = 10 ether;
        uint8 USDC_DECIMALS = 6;
        uint256 _latestPrice = 2541977100;

        uint256 _swapAmount = (uint256(_amount) * uint256(_latestPrice) * 10**18) / 10**(_stratDecimals + 8 - USDC_DECIMALS) / 10**18;

        console2.log(_swapAmount);

        assertGt(_swapAmount,0);

    }

    // Fix made so _swapAmount is greater than 0.
    // This test shows swapping to a token with 6 decimals still works fine
    function test_SwapSlippageFix2() public {
        //vm.assume(_stratDecimals > 7 && _stratDecimals <= 18);
        uint8 _stratDecimals = 6;    
        uint256 _amount = 1_000e6;
        uint8 USDC_DECIMALS = 6;
        uint256 _latestPrice = 99999999;

        uint256 _swapAmount = (uint256(_amount) * uint256(_latestPrice) * 10**18) / 10**(_stratDecimals + 8 - USDC_DECIMALS) / 10**18;

        console2.log(_swapAmount);

        assertGt(_swapAmount,0);

    }

    // Fuzz test fix
    function testFuzz_SwapSlippageFix(uint80 _amount, uint8 _stratDecimals, uint56 _latestPrice) public {
        vm.assume(
            _amount > 10_000 &&
            _amount < 1_000_000 ether &&
            _stratDecimals >=6 && 
            _stratDecimals <= 18 &&
            _latestPrice > 1000000 &&
            _latestPrice < 1_000_000 * 10**8 &&
            uint256(_amount) * uint256(_latestPrice) / 10**(8 + _stratDecimals) > 0 // amount cannot be minute fractions of a penny
        );

        uint8 USDC_DECIMALS = 6;

        uint256 _swapAmount = (uint256(_amount) * uint256(_latestPrice) * 10**18) / 10**(_stratDecimals + 8 - USDC_DECIMALS) / 10**18;

        assertGt(_swapAmount,0);

    }

    // Fix changes formula so multiplication is before division
    // Problem with small numbers is resolved
    function testFuzz_WNativeSwapSlippageAmountFix(uint80 _amount) public {
        vm.assume(_amount > 0 && _amount < 0.96 ether);

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;
        uint256 _latestPriceNative = 2541977100;
        uint256 _latestPriceTokenB = 2641977100;

        uint256 _swapAmount = _amount * _latestPriceTokenB * 10**18 * 10**(WNATIVE_DECIMALS - _stratDecimals) / 10**18 / _latestPriceNative;

        assertGt(_swapAmount,0);

    }

    // Fuzz test with any amount
    function testFuzz_WNativeSwapSlippageAmountFix2(uint80 _amount, uint56 _latestPriceNative, uint56 _latestPriceTokenB) public {
        vm.assume(
            _amount > 0 && 
            _amount < 1_000_000 ether &&
            _latestPriceNative > 0 &&
            _latestPriceTokenB > 0 &&
            _latestPriceNative < 1_000_000 * 10**8 &&
            _latestPriceTokenB < 1_000_000 * 10**8 &&
            _latestPriceNative <= _latestPriceTokenB
        );

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;

        uint256 _swapAmount = uint256(_amount) * uint256(_latestPriceTokenB) * 10**18 * 10**(WNATIVE_DECIMALS - _stratDecimals) / 10**18 / uint256(_latestPriceNative);

        assertGt(_swapAmount,0); // this is calculated correctly as greater than 0
    }


    // Fix corrects issue when tokenB price is less than native price
    function testFuzz_WNativeSwapSlippagePriceFix(uint80 _amount) public {
        vm.assume(
            _amount > 1 ether && 
            _amount < 1_000_000 ether 
        );

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;

        uint256 _latestPriceNative = 2541977100;
        uint256 _latestPriceTokenB = 2500;

        uint256 _swapAmount = uint256(_amount) * uint256(_latestPriceTokenB) * 10**18 * 10**(WNATIVE_DECIMALS - _stratDecimals) / 10**18 / uint256(_latestPriceNative);

        assertGt(_swapAmount,0);

    }

    // Fix also works when tokenB price is greater than or equal to native price
    function testFuzz_WNativeSwapSlippagePriceFix2(uint80 _amount, uint56 _latestPriceNative, uint56 _latestPriceTokenB) public {
        vm.assume(
            _amount > 1 ether && 
            _amount < 1_000_000 ether &&
            _latestPriceNative > 1000 &&
            _latestPriceTokenB > 10000 &&
            _latestPriceNative < 10_000_000 * 10**8 &&
            _latestPriceTokenB < 10_000_000 * 10**8 &&
            _latestPriceNative <= _latestPriceTokenB
        );

        uint8 _stratDecimals = 18; // Variable comes from Strategy structure and is seen as _strat.decimals in the contract
        uint8 WNATIVE_DECIMALS = 18;

        uint256 _swapAmount = uint256(_amount) * uint256(_latestPriceTokenB) * 10**18 * 10**(WNATIVE_DECIMALS - _stratDecimals) / 10**18 / uint256(_latestPriceNative);

        console2.log(_swapAmount); // this is greater than 0
        assertGt(_swapAmount,0);

    }

}
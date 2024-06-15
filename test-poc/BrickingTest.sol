pragma solidity ^0.8.21;

// utilities
import { Test, console2 } from "forge-std/Test.sol";
import { FortiFiFeeManager } from "src/fee-managers/FortiFiFeeManager.sol";
import { FortiFiFeeCalculator } from "src/fee-calculators/FortiFiFeeCalculator.sol";
import { FortiFiWombatStrategy } from "src/strategies/FortiFiWombatStrategy.sol";
import { FortiFiGLPStrategy } from "src/strategies/FortiFiGLPStrategy.sol";
import { FortiFiMASSVaultV2 } from "src/vaults/FortiFiMASSVaultV2.sol";
import { FortiFiWNativeMASSVaultV2 } from "src/vaults/FortiFiWNativeMASSVaultV2.sol";
import { IMASS } from "src/vaults/interfaces/IMASS.sol";
import { WAVAX } from "src/mock/WAVAX.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// This test shows that setting a FortiFiStrategy as bricked only works properly when the 
// strategy deposit token is the same as the MultiYield deposit token
contract BaseTest is Test, ERC1155Holder {
    address constant FORTIFI_OWNER_ADDRESS = 0xa79dF98FB95b0392a045d2B93B76DE9e28a8dA88;

    string AVALANCHE_RPC_URL = 'https://api.avax.network/ext/bc/C/rpc';
    uint256 avalancheFork;
    WAVAX wavax;
    IERC20 usdc;

    //currently deployed contracts
    FortiFiGLPStrategy glpStrategy;
    FortiFiWombatStrategy ggAvaxStrategy;
    FortiFiWombatStrategy sAvaxStrategy;
    FortiFiMASSVaultV2 stabilityMY;
    FortiFiWNativeMASSVaultV2 lstMY;

    function setUp() public {
        avalancheFork = vm.createFork(AVALANCHE_RPC_URL);
        vm.selectFork(avalancheFork);

        wavax = WAVAX(payable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7));
        usdc = IERC20(payable(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E));
        glpStrategy = FortiFiGLPStrategy(0x72a1702785E1208973819B9F692801ab26FCa882);
        ggAvaxStrategy = FortiFiWombatStrategy(0x666d883b9d5BB40f4d100d3c9919abfE29608F30);
        sAvaxStrategy = FortiFiWombatStrategy(0xca33e819B1A3e519b02830cED658Fd0543599410);
        stabilityMY = FortiFiMASSVaultV2(payable(0x432963C721599Cd039ff610Fad447D487380D858));
        lstMY = FortiFiWNativeMASSVaultV2(payable(0x853e7A9dcc5037cD624834DC5f33151AA49d2D73));
    }

    // Show that bricking strategies that have the same deposit token than the MultiYield succeeds
    function testWithdrawAfterBrickingGLP() public {
        deal(address(usdc), address(this), 10000e6);

        // approve the use of wavax and deposit
        usdc.approve(address(stabilityMY), 1000e6);
        (uint256 _tokenId, ) = stabilityMY.deposit(500e6);

        // brick GLP strategy
        vm.prank(FORTIFI_OWNER_ADDRESS);
        glpStrategy.setStrategyBricked(true);

        // withdraw succeeds
        stabilityMY.withdraw(_tokenId);

        // verify user has received Yak GLP YRT
        uint256 yrtBalance = IERC20(0x9f637540149f922145c06e1aa3f38dcDc32Aff5C).balanceOf(address(this));

        assertGt(yrtBalance, 0);
    }

    // Show that bricking strategies that have a different deposit token than the MultiYield fails
    function testWithdrawAfterBrickingGGAvax() public {
        deal(address(wavax), address(this), 10000e18);

        // approve the use of wavax and deposit
        wavax.approve(address(lstMY), 100e18);
        (uint256 _tokenId, ) = lstMY.deposit(50e18);

        // brick ggAvax strategy
        vm.prank(FORTIFI_OWNER_ADDRESS);
        ggAvaxStrategy.setStrategyBricked(true);

        // now withdrawing should fail due to trying to swap 0
        vm.expectRevert();
        lstMY.withdraw(_tokenId);
    }

    // Show that adding check in router can resolve the issue
    function testWithdrawAfterFix() public {
        // deploy new "brickable" router and set MultiYield strategies
        FortiFiGGAvaxRouterBrickable newRouter = new FortiFiGGAvaxRouterBrickable();
        IMASS.Strategy[] memory newStrategies = new IMASS.Strategy[](2);

        newStrategies[0] = IMASS.Strategy({
            strategy: 0xca33e819B1A3e519b02830cED658Fd0543599410, // YY Wombat sAVAX
            depositToken: 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE,
            router: 0x8B8CB06b4e9b171064345E32ff575C77cA805CE3, 
            oracle: 0x0C53b73EfDdE61874C945395a813253326dE8eEA,
            isFortiFi: true, 
            isSAMS: false,
            bps: 5000,
            decimals: 18
        });

        newStrategies[1] = IMASS.Strategy({
            strategy: 0x666d883b9d5BB40f4d100d3c9919abfE29608F30, // YY Wombat ggAVAX
            depositToken: 0xA25EaF2906FA1a3a13EdAc9B9657108Af7B703e3,
            router: address(newRouter), 
            oracle: 0x4a30CB77AAC31c9B7feC0700FEaCd3Bdb44147F6,
            isFortiFi: true, 
            isSAMS: false,
            bps: 5000,
            decimals: 18
        });

        vm.prank(FORTIFI_OWNER_ADDRESS);
        lstMY.setStrategies(newStrategies);

        deal(address(wavax), address(this), 10000e18);

        // approve the use of wavax and deposit
        wavax.approve(address(lstMY), 100e18);
        (uint256 _tokenId, ) = lstMY.deposit(50e18);

        // brick ggAvax strategy
        vm.prank(FORTIFI_OWNER_ADDRESS);
        ggAvaxStrategy.setStrategyBricked(true);

        // withdraw now works
        lstMY.withdraw(_tokenId);

        // verify user has received Yak Wombat-ggAVAX YRT
        uint256 yrtBalance = IERC20(0x13404B1C715aF60869fc658d6D99c117e3543592).balanceOf(address(this));

        assertGt(yrtBalance, 0);
    }

    // Check that sAVAX partially works. As the first strategy there needs to be wavax in the contract to make the funds recoverable
    function testWithdrawAfterFix2() public {
        // deploy new "brickable" router and set MultiYield strategies
        FortiFiLBRouterBrickable newRouter = new FortiFiLBRouterBrickable(0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30, 5);
        IMASS.Strategy[] memory newStrategies = new IMASS.Strategy[](2);

        newStrategies[0] = IMASS.Strategy({
            strategy: 0xca33e819B1A3e519b02830cED658Fd0543599410, // YY Wombat sAVAX
            depositToken: 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE,
            router: address(newRouter), 
            oracle: 0x0C53b73EfDdE61874C945395a813253326dE8eEA,
            isFortiFi: true, 
            isSAMS: false,
            bps: 5000,
            decimals: 18
        });

        newStrategies[1] = IMASS.Strategy({
            strategy: 0x666d883b9d5BB40f4d100d3c9919abfE29608F30, // YY Wombat ggAVAX
            depositToken: 0xA25EaF2906FA1a3a13EdAc9B9657108Af7B703e3,
            router: 0xa5eeC52Dd815Ee7b3b91Da8AF5FacE1aA996336C, 
            oracle: 0x4a30CB77AAC31c9B7feC0700FEaCd3Bdb44147F6,
            isFortiFi: true, 
            isSAMS: false,
            bps: 5000,
            decimals: 18
        });

        vm.prank(FORTIFI_OWNER_ADDRESS);
        lstMY.setStrategies(newStrategies);

        deal(address(wavax), address(this), 10000e18);

        // approve the use of wavax and deposit
        wavax.approve(address(lstMY), 100e18);
        (uint256 _tokenId, ) = lstMY.deposit(50e18);

        // brick sAvax strategy
        vm.prank(FORTIFI_OWNER_ADDRESS);
        sAvaxStrategy.setStrategyBricked(true);

        // withdrawal fails because there is no wavax in contract
        vm.expectRevert();
        lstMY.withdraw(_tokenId);

        // send 1 wei wavax to contract and withdraw now works
        wavax.transfer(address(lstMY), 1); 
        lstMY.withdraw(_tokenId);

        // verify user has received Yak Wombat-sAVAX YRT
        uint256 yrtBalance = IERC20(0x9B5d890d563EE4c9255bB500a790Ca6B1FB9dB6b).balanceOf(address(this));

        assertGt(yrtBalance, 0);
    }

    // Show that sending deposit tokens to the contract allow for withdrawal of ggAVAX
    function testWithdrawAfterBrickingGGAvaxWorkaround() public {
        address gg = 0xA25EaF2906FA1a3a13EdAc9B9657108Af7B703e3;
        deal(address(wavax), address(this), 10000e18);
        deal(gg, address(this), 10000e18);

        // approve the use of wavax and deposit
        wavax.approve(address(lstMY), 100e18);
        (uint256 _tokenId, ) = lstMY.deposit(50e18);

        // brick ggAvax strategy
        vm.prank(FORTIFI_OWNER_ADDRESS);
        ggAvaxStrategy.setStrategyBricked(true);

        // now withdrawing should fail due to trying to swap 0
        vm.expectRevert();
        lstMY.withdraw(_tokenId);

        // send some ggAVAX to the contract
        IERC20 ggAvax = IERC20(gg);
        ggAvax.transfer(address(lstMY), 1);

        // withdraw now works
        lstMY.withdraw(_tokenId);

        // verify user has received Yak Wombat-ggAVAX YRT
        uint256 yrtBalance = IERC20(0x13404B1C715aF60869fc658d6D99c117e3543592).balanceOf(address(this));

        assertGt(yrtBalance, 0);
    }

    // Show that sending deposit tokens to the contract allow for withdrawal of sAVAX
    function testWithdrawAfterBrickingSAvaxWorkaround() public {
        address s = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
        deal(address(wavax), address(this), 10000e18);
        deal(s, address(this), 10000e18);

        // approve the use of wavax and deposit
        wavax.approve(address(lstMY), 100e18);
        (uint256 _tokenId, ) = lstMY.deposit(50e18);

        // brick ggAvax strategy
        vm.prank(FORTIFI_OWNER_ADDRESS);
        sAvaxStrategy.setStrategyBricked(true);

        // now withdrawing should fail due to trying to swap 0
        vm.expectRevert();
        lstMY.withdraw(_tokenId);

        // send some ggAVAX to the contract
        IERC20 sAvax = IERC20(s);
        sAvax.transfer(address(lstMY), 10000);

        // withdraw now works
        lstMY.withdraw(_tokenId);

        // verify user has received Yak Wombat-sAVAX YRT
        uint256 yrtBalance = IERC20(0x9B5d890d563EE4c9255bB500a790Ca6B1FB9dB6b).balanceOf(address(this));

        assertGt(yrtBalance, 0);
    }

}
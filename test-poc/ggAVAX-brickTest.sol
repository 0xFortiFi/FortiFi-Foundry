pragma solidity ^0.8.21;

// utilities
import { Test, console2 } from "forge-std/Test.sol";
import { FortiFiWombatStrategy } from "src/strategies/FortiFiWombatStrategy.sol";
import { FortiFiWNativeMASSVaultV2 } from "src/vaults/FortiFiWNativeMASSVaultV2.sol";
import { FortiFiWombatGGAvaxZapper } from "src/zappers/FortiFiWombatGGAvaxZapper.sol";
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
    IERC20 yrt = IERC20(0x13404B1C715aF60869fc658d6D99c117e3543592);

    //currently deployed contracts
    FortiFiWombatStrategy ggAvaxStrategy;
    FortiFiWNativeMASSVaultV2 lstMY;

    function setUp() public {
        avalancheFork = vm.createFork(AVALANCHE_RPC_URL);
        vm.selectFork(avalancheFork);
    
        wavax = WAVAX(payable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7));
        ggAvaxStrategy = FortiFiWombatStrategy(0x666d883b9d5BB40f4d100d3c9919abfE29608F30);
        lstMY = FortiFiWNativeMASSVaultV2(payable(0x853e7A9dcc5037cD624834DC5f33151AA49d2D73));
    }


    // Show that sending deposit tokens to the contract allow for withdrawal of ggAVAX
    function testWithdrawAfterBrickingGGAvaxWorkaround() public {
        address gg = 0xA25EaF2906FA1a3a13EdAc9B9657108Af7B703e3;
        deal(gg, address(this), 10000e18);

        // transfer an old receipt to this address
        vm.prank(0x625d271F634eE0804CCc573C4679aA3AeE475B62);
        lstMY.safeTransferFrom(0x625d271F634eE0804CCc573C4679aA3AeE475B62, address(this), 8, 1, "");

        // change strategy configuration to 100% wombat sAVAX
        IMASS.Strategy[] memory newStrategies = new IMASS.Strategy[](1);

        newStrategies[0] = IMASS.Strategy({
            strategy: 0xca33e819B1A3e519b02830cED658Fd0543599410, // YY Wombat sAVAX
            depositToken: 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE,
            router: 0x8B8CB06b4e9b171064345E32ff575C77cA805CE3, 
            oracle: 0x0C53b73EfDdE61874C945395a813253326dE8eEA,
            isFortiFi: true, 
            isSAMS: false,
            bps: 10000,
            decimals: 18
        });

        vm.startPrank(FORTIFI_OWNER_ADDRESS);
        lstMY.setStrategies(newStrategies);
        ggAvaxStrategy.setStrategyBricked(true);
        vm.stopPrank();

        // send some ggAVAX to the contract
        IERC20 ggAvax = IERC20(gg);
        ggAvax.transfer(address(lstMY), 1);

        // withdraw now works
        lstMY.rebalance(8);

        // verify user has received Yak Wombat-ggAVAX YRT
        uint256 yrtBalance = yrt.balanceOf(address(this));

        assertGt(yrtBalance, 0);

        // deploy zapper
        FortiFiWombatGGAvaxZapper zapper = new FortiFiWombatGGAvaxZapper();

        yrt.approve(address(zapper), yrtBalance);

        // get before wavax balance
        uint256 _beforeBalance = wavax.balanceOf(address(this));
        console2.log(_beforeBalance);
        // zap
        zapper.zap(yrtBalance, 10602);

        // get after wavax balance
        uint256 _afterBalance = wavax.balanceOf(address(this));
        console2.log(_afterBalance);
        assertGt(_afterBalance, _beforeBalance);
    }

}
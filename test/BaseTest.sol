pragma solidity ^0.8.21;

// utilities
import { Test, console2 } from "forge-std/Test.sol";
import { FortiFiFeeManager } from "src/fee-managers/FortiFiFeeManager.sol";
import { FortiFiFeeCalculator } from "src/fee-calculators/FortiFiFeeCalculator.sol";
import { FortiFiLBRouter } from "src/routers/FortiFiLBRouter.sol";
import { FortiFiGGAvaxRouter } from "src/routers/FortiFiGGAvaxRouter.sol";
import { FortiFiDIAPriceOracle } from "src/oracles/FortiFiDIAPriceOracle.sol";
import { FortiFiMockOracle } from "src/oracles/FortiFiMockOracle.sol";
import { FortiFiPriceOracle } from "src/oracles/FortiFiPriceOracle.sol";
import { FortiFiWombatStrategy } from "src/strategies/FortiFiWombatStrategy.sol";
import { FortiFiGLPStrategy } from "src/strategies/FortiFiGLPStrategy.sol";
import { FortiFiNativeStrategy } from "src/strategies/FortiFiNativeStrategy.sol";
import { FortiFiMASSVaultV2 } from "src/vaults/FortiFiMASSVaultV2.sol";
import { FortiFiWNativeMASSVaultV2 } from "src/vaults/FortiFiWNativeMASSVaultV2.sol";
import { IMASS } from "src/vaults/interfaces/IMASS.sol";
import { WAVAX } from "src/mock/WAVAX.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// This base test setup gives a starting point for all tests, and shows how to create implementations of all currently
// deployed FortiFi Contracts
contract BaseTest is Test, ERC1155Holder {
    address constant FORTIFI_OWNER_ADDRESS = 0xa79dF98FB95b0392a045d2B93B76DE9e28a8dA88;

    string AVALANCHE_RPC_URL = 'https://api.avax.network/ext/bc/C/rpc';
    uint256 avalancheFork;
    WAVAX wavax;
    IERC20 usdc;

    //currently deployed contracts
    FortiFiFeeManager feeMgr;
    FortiFiFeeCalculator feeCalcStability;
    FortiFiFeeCalculator feeCalcLST;
    FortiFiPriceOracle avaxOracle;
    FortiFiDIAPriceOracle sAvaxOracle;
    FortiFiDIAPriceOracle usdtOracle;
    FortiFiMockOracle ggAvaxOracle;
    FortiFiLBRouter sAvaxRouter;
    FortiFiLBRouter usdtRouter;
    FortiFiGGAvaxRouter ggAvaxRouter;
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
        feeMgr = FortiFiFeeManager(0xf964894470AfC11037f6BCB38609f77e9EBA9851);
        feeCalcStability = FortiFiFeeCalculator(0x97F9fE54Aa908Ac0E8B2D10244bd4bba87D51160);
        feeCalcLST = FortiFiFeeCalculator(0xC15711C7C8DEAc7A360f9B8826E7c151088D0d8C);
        avaxOracle = FortiFiPriceOracle(0xdFABbc3d82b8234A88A9f64faAB1f514a857a3dF);
        sAvaxOracle = FortiFiDIAPriceOracle(0x0C53b73EfDdE61874C945395a813253326dE8eEA);
        usdtOracle = FortiFiDIAPriceOracle(0xDC655E3Dc8f36096c779294D03C62b3af15De8b0);
        ggAvaxOracle = FortiFiMockOracle(0x4a30CB77AAC31c9B7feC0700FEaCd3Bdb44147F6);
        sAvaxRouter = FortiFiLBRouter(0x8B8CB06b4e9b171064345E32ff575C77cA805CE3);
        usdtRouter = FortiFiLBRouter(0xd2746098C8Ff73CD676f293B061248B124eb2806);
        ggAvaxRouter = FortiFiGGAvaxRouter(payable(0xa5eeC52Dd815Ee7b3b91Da8AF5FacE1aA996336C));
        glpStrategy = FortiFiGLPStrategy(0x45e1762b617140692daa80857B6a8b1C3229A25B);
        ggAvaxStrategy = FortiFiWombatStrategy(0x666d883b9d5BB40f4d100d3c9919abfE29608F30);
        sAvaxStrategy = FortiFiWombatStrategy(0xca33e819B1A3e519b02830cED658Fd0543599410);
        stabilityMY = FortiFiMASSVaultV2(payable(0x432963C721599Cd039ff610Fad447D487380D858));
        lstMY = FortiFiWNativeMASSVaultV2(payable(0x853e7A9dcc5037cD624834DC5f33151AA49d2D73));
    }

    // deposit, add, and withdraw from vaults
    function testDepositAddWithdrawStability() public {
        deal(address(usdc), address(this), 10000e6);

        // approve the use of wavax and deposit
        usdc.approve(address(stabilityMY), 1000e6);
        (uint256 _tokenId, IMASS.TokenInfo memory _info) = stabilityMY.deposit(500e6);

        console2.log(_info.deposit);

        // add to deposit and get new tokenInfo
        stabilityMY.add(500e6, _tokenId);
        IMASS.TokenInfo memory _info2 = stabilityMY.getTokenInfo(_tokenId);
        
        console2.log(_info2.deposit);

        // get before balance, withdraw, get after balance
        uint256 beforeBalance = usdc.balanceOf(address(this)); // should be 9000e6
        stabilityMY.withdraw(_tokenId);
        uint256 afterBalance = usdc.balanceOf(address(this));

        console2.log(afterBalance); // should be close to 10000e6;

        assertGt(afterBalance, beforeBalance);
    }

    // deposit, add, and withdraw from vaults
    function testDepositAddWithdrawLST() public {
        deal(address(wavax), address(this), 10000e18);

        // approve the use of wavax and deposit
        wavax.approve(address(lstMY), 100e18);
        (uint256 _tokenId, IMASS.TokenInfo memory _info) = lstMY.deposit(50e18);

        console2.log(_info.deposit);

        // add to deposit and get new tokenInfo
        lstMY.add(50e18, _tokenId);
        IMASS.TokenInfo memory _info2 = lstMY.getTokenInfo(_tokenId);
        
        console2.log(_info2.deposit);

        // get before balance, withdraw, get after balance
        uint256 beforeBalance = wavax.balanceOf(address(this)); // should be 9900e18
        lstMY.withdraw(_tokenId);
        uint256 afterBalance = wavax.balanceOf(address(this));

        console2.log(afterBalance); // should be close to 10000e18;

        assertGt(afterBalance, beforeBalance);
    }

}
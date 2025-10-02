// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralizedStablecoin} from "src/DecentralizedStablecoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DSCEngine dscEngine;
    DeployDSC deployer;
    DecentralizedStablecoin dsc;
    HelperConfig config;

    address ethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;

    address user = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    modifier depositCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (ethUsdPriceFeed, wbtcUsdPriceFeed, weth, , ) = config
            .activeNetworkConfig();

        ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
    }

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30_000e18;
        uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testRevertIfCollateralZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__NeedsMoreThanZero.selector
            )
        );
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        address[] memory tokenAddresses = new address[](1);
        address[] memory priceFeeds = new address[](2);

        tokenAddresses[0] = weth;

        priceFeeds[0] = ethUsdPriceFeed;
        priceFeeds[1] = wbtcUsdPriceFeed;

        vm.expectRevert(
            DSCEngine.DSCEngine_AddressArraysNotSameLength.selector
        );
        new DSCEngine(tokenAddresses, priceFeeds, address(dsc));
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        uint256 exoectedWeth = 0.05 ether;
        uint256 actualWeth = dscEngine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(exoectedWeth, actualWeth);
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock fakeToken = new ERC20Mock(
            "FAKE",
            "FK",
            msg.sender,
            AMOUNT_COLLATERAL
        );
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine_TokenNotAllowed.selector);
        dscEngine.depositCollateral(address(fakeToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }
}

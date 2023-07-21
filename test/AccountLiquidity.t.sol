// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "./utils/TestUtils.sol";

/// @notice 计算账户的流动性
contract AccountLiquidityTest is Test, TestUtils {
    function setUp() public {
        // fork主网 16_401_180.的区块
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
    }

    function testAccountLiquidity() public {
        // 用1ETH来得到对应的cETH
        cEther.mint{value: 1 ether}();

        // 本合约进入Compound的市场
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        unitroller.enterMarkets(cTokens); // <- we enter here

        // We get the collateral factor.
        (, uint256 collateralFactorMantissa,) = unitroller.markets(address(cEther));

        // We get the account's liquidity.
        (, uint256 liquidity,) = unitroller.getAccountLiquidity(address(this));
        liquidity = liquidity / 1e18;

        // We get the Eth price from the oracle.
        uint256 price = oracle.getUnderlyingPrice(address(cEther));

        uint256 expectedLiquidity = (price * collateralFactorMantissa / 1e18) / 1e18;

        // Should match.
        assertEq(liquidity, expectedLiquidity);
    }
}

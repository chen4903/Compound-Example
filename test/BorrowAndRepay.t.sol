// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "./utils/TestUtils.sol";

/// @notice 借款，还款
// forge test --match-path test/BorrowAndRepay.t.sol -vvvv
contract BorrowAndRepayTest is Test, TestUtils {
    function setUp() public {
        // fork主网 16_401_180.的区块
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
    }

    // 质押ETH到Compound，借款，检查余额，计算利息，还款
    function testBorrowAndRepay() public {
        // 我们本合约目前没有任何 DAI
        assertEq(dai.balanceOf(address(this)), 0);

        // 用1ETH来得到对应的cETH
        cEther.mint{value: 1 ether}();

        // 本合约进入Compound的市场
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEther);
        unitroller.enterMarkets(cTokens); // <- we enter here

        // 查看本合约进入市场的资产是不是cETH
        address[] memory assetsIn = unitroller.getAssetsIn(address(this));
        assertEq(assetsIn[0], address(cEther));

        // 借500个 DAI
        uint256 borrowAmount = 500 * 1e18; // 500 DAI
        cDai.borrow(borrowAmount);

        // 本合约应该有 500 个DAI
        assertEq(dai.balanceOf(address(this)), borrowAmount);

        // 还DAI
        dai.approve(address(cDai), borrowAmount); // 先授权，因为Compound是用transferFrom()还款的
        cDai.repayBorrow(borrowAmount);

        // 还款完之后，本合约中的DAI余额应该为0
        assertEq(dai.balanceOf(address(this)), 0);
    }
}
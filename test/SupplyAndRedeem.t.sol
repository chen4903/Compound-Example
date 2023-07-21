// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "./utils/TestUtils.sol";

/// @notice 存款，然后取款

// forge test --match-path test/SupplyAndRedeem.t.sol -vvvv
contract SupplyAndRedeemTest is Test, TestUtils {

    function setUp() public {
        // fork主网 16401180.的区块
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);
    }

    // 向Compound存款，然后检查余额是否正确，再检查利润(accrues interests)，最后取款
    function testSupplyAndRedeem() public {
        // 本合约最初的ETH余额，我们最后会做个比较。foundry默认测试的账户有一定的ETH
        uint256 initialEthBalance = address(this).balance;

        // 我们最初的cETH应该是0
        assertEq(cEther.balanceOf(address(this)), 0);

        // mint一个ETH数量的cETH
        cEther.mint{value: 1 ether}();

        // 我们获取ETH和cETH之间的汇率，作为学习
        uint256 exchangeRate = getExchangeRate();

        // 我们获取本合约中的cETH数量
        uint256 cEtherBalance = cEther.balanceOf(address(this));

        // 看看我们计算出来的cETH和实际获取的是否相同
        uint256 mintTokens = 1 ether * 1e18 / exchangeRate;
        assertEq(cEtherBalance, mintTokens);

        // 增加一个区块
        vm.roll(block.number + 1);

        // 将cETH换回ETH，包含了本金和利润
        require(cEther.redeem(cEther.balanceOf(address(this))) == 0, "redeem failed");

        // 看看是否真的取回了所有资产，如果都取回了，那cETH的数量是0
        assertEq(cEther.balanceOf(address(this)), 0);

        // ETH本金 + 一个区块的利润 > ETH 本金
        assert(address(this).balance > initialEthBalance);
    }

    // 计算ETH和cETH之间的汇率
    function getExchangeRate() internal returns (uint256) {
        // exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply.
        uint256 totalCash = cEther.getCash();
        assertEq(totalCash, address(cEther).balance);

        uint256 totalBorrows = cEther.totalBorrowsCurrent();
        assert(totalBorrows > 0);

        uint256 totalReserves = cEther.totalReserves();
        assert(totalReserves > 0);

        uint256 totalSupply = cEther.totalSupply();
        assert(totalSupply > 0);

        uint256 exchangeRate = 1e18 * (totalCash + totalBorrows - totalReserves) / totalSupply;
        return exchangeRate;
    }

    receive() external payable {}
}

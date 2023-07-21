// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";

import "../src/NewComptroller.sol";
import "./utils/TestUtils.sol";

/// @notice 升级unitroller的的Comptroller，也就是unitroller中的fallback的delegate将会访问到的合约
// 这个测试包含了整个投票执行过程
// 1. 创建一个提案
// 2. 投票
// 3. 在Timelock中排队
// 4. 执行提案
// 运行：forge test --match-path test/UpgradeComptroller.t.sol -vvvv

contract UpgradeComptrollerTest is Test, TestUtils {
    NewComptroller newComptroller; // 我们新的Comptroller

    function setUp() public {
        // Fork 主网的 16_401_180 区块
        cheat.createSelectFork("mainnet", BLOCK_NUMBER);

        uint256 TRANSFER_AMOUNT = 400_000 * 1e18;

        // 用这个账户进行测试，因为这个账户有很多COMP，当然也可以换成其他有大量COMP的账户
        cheat.startPrank(0x2775b1c75658Be0F640272CCb8c72ac986009e38);
        // 向本合约转 TRANSFER_AMOUNT 数量的COMP
        comp.transfer(address(this), TRANSFER_AMOUNT);
        cheat.stopPrank();

        assertEq(comp.balanceOf(address(this)), TRANSFER_AMOUNT);

        // 让本合约自己代理投票权
        comp.delegate(address(this));

        // 增加一个区块高度，然后查询是否本合约是否有这么多投票权。因为是查询不到当前区块中的状态的
        vm.roll(block.number + 1);
        assertEq(comp.getPriorVotes(address(this), block.number - 1), TRANSFER_AMOUNT);

        // 创建新的 Comptroller 实例
        newComptroller = new NewComptroller();

    }

    // @notice 这个测试包含了整个投票执行过程
    // 这个测试的结果是： 升级了新的Comptroller
    function testUpgradeComptroller() public {
        // 1. 创建、发起提案，并获取提案的ID
        uint256 proposalId = propose();

        // 获取投票等待期，只有超过这个投票等待期，才可以进行投票
        // 我们用作弊码来推进区块状态
        uint256 votingDelay = gBravo.votingDelay(); // 13140 blocks
        vm.roll(block.number + votingDelay + 1);

        // 2.投票给我们的提案
        gBravo.castVote(proposalId, 1); // 0=against, 1=for, 2=abstain

        // 获取投票结束期限，只有超过这个投票结束期限，投票才结束
        // 我们用作弊码来推进区块状态
        uint256 votingPeriod = gBravo.votingPeriod(); // 19710 blocks
        vm.roll(block.number + votingPeriod);

        // 3.我们将我们的提案加入到Timelock中的队列，等待执行
        // PS：因为这个提案只有我们投票，只有支持没有反对票，并且投票数额是足够的，因此可以这个提案会success
        gBravo.queue(proposalId);

        // 获取等待执行的时间
        uint256 timelockDelay = timelock.delay();

        // 推进区块时间戳状态
        vm.warp(block.timestamp + timelockDelay);

        // 4. 执行提案
        gBravo.execute(proposalId);

        // 需要 unitroller 接收新的实现类newComptroller才能够生效
        newComptroller.acceptImplementation(address(unitroller));

        // 我们看看新的实现类 newComptroller 是否成功了
        // unitroller 调用testImplementation()会走到fallback中，然后delegate到newComptroller，也就是新的实现类
        (bool success, bytes memory data) = address(unitroller).staticcall(abi.encodeWithSignature("testImplementation()"));
        require(success);
        string memory result = abi.decode(data, (string));
        assertEq(result, "I am the new Comptroller");
    }

    function propose() internal returns (uint256) {
        // 第一个参数：Unitroller实际调用delegate给的Comptroller，也就是旧的Comptroller
        address[] memory targets = new address[](1);
        targets[0] = address(unitroller);

        // 第二个参数：发送的ETH数量
        uint256[] memory values = new uint[](1);
        values[0] = 0;

        // 第三个参数：签名信息
        string[] memory signatures = new string[](1);
        signatures[0] = "";

        // 第四个参数：这个提案将要做的事情
        bytes[] memory calldatas = new bytes[](1);
        // 这里只是设置pending中的newComptroller,当此提案成功后，
        // 还需要newComptroller来调用unitroller的_acceptImplementation来确认newComptroller
        calldatas[0] = abi.encodeWithSignature("_setPendingImplementation(address)", address(newComptroller));

        // 第五个参数：提案的描述
        string memory description = "Upgrades the Comptroller";

        // 使用治理合约来发起一个提案，并获得此提案的ID
        uint256 proposalId = gBravo.propose(targets, values, signatures, calldatas, description);
        require(proposalId > 0, "Proposal failed");
        return proposalId;
    }

    receive() external payable {}
}

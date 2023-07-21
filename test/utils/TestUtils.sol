// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "forge-std/Test.sol";
import "../interface.sol";

contract TestUtils is Test {
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /// @dev COMP token.
    ERC20Interface comp = ERC20Interface(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    /// @dev cEther compound.
    CTokenInterface cEther = CTokenInterface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    /// @dev cDai compound.
    CTokenInterface cDai = CTokenInterface(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    /// @dev 主要的治理合约
    GovernorBravoInterface gBravo = GovernorBravoInterface(0xc0Da02939E1441F497fd74F78cE7Decb17B66529);

    /// @dev The Timelock.
    TimelockInterface timelock = TimelockInterface(0x6d903f6003cca6255D85CcA4D3B5E5146dC33925);

    /// @dev Unitroller合约，它的fallback会delegate到Comptroller合约进行方法调用
    ComptrollerInterface unitroller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /// @dev Dai.
    ERC20Interface dai = ERC20Interface(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    /// @dev 预言机，用于获取token价格
    OracleInterface oracle = OracleInterface(0x50ce56A3239671Ab62f185704Caedf626352741e);

    /// @dev fork主网的区块高度
    uint256 public constant BLOCK_NUMBER = 16_401_180;

    constructor() public {
        // 打标签，这样-vvvv追踪调用就更好理解了
        vm.label(address(comp),"comp");
        vm.label(address(cEther),"cEther");
        vm.label(address(cDai),"cDai");
        vm.label(address(gBravo),"gBravo");
        vm.label(address(timelock),"timelock");
        vm.label(address(unitroller),"unitroller");
        vm.label(address(dai),"dai");
    }
}

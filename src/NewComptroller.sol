// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract NewComptroller {
    
    // 用 NewComptroller 来调用 unitroller 来设置新的 comptroller 
    function acceptImplementation(address unitroller) external {
        bytes4 callData = bytes4(keccak256("_acceptImplementation()"));

        (bool success,) = unitroller.call(abi.encodeWithSelector(callData));
        require(success, "unitroller: failed to accept implementation");
    }

    // 用于测试
    function testImplementation() external pure returns (string memory) {
        return "I am the new Comptroller";
    }
}
pragma solidity ^0.5.17;

interface IERC20 {
    function name() external view returns (string memory);
    function balanceOf(address target) external view returns (uint256);
}

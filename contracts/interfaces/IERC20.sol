pragma solidity >=0.4.25 <0.7.0;

interface IERC20 {
    function name() external view returns (string memory);
    function balanceOf(address target) external view returns (uint256);
}

pragma solidity >=0.4.25 <0.7.0;
pragma solidity ^0.4.0;

interface IERC20 {
    function name() external view returns (string);
    function balanceOf(address target) external view returns (uint256);
}

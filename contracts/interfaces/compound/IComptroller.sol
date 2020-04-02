pragma solidity ^0.5.17;

interface IComptroller {
    function getAssetsIn(address account) external view returns (address[] memory assets);
    function markets(address asset) external view returns (bool, uint256);
}

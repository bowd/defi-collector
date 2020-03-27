pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

interface IComptroller {
    function getAssetsIn(address account) external view returns (address[] memory assets);
    function markets(address asset) external view returns (bool, uint256);
}

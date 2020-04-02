pragma solidity ^0.5.17;

interface ICompoundPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

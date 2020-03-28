pragma solidity >=0.4.25 <0.7.0;

interface IPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

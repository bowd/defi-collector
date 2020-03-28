pragma solidity >=0.4.25 <0.7.0;

interface IProxyRegistry {
    function proxies(address input) external view returns (address);
}

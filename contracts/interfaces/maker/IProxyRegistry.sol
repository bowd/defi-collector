pragma solidity ^0.5.17;

interface IProxyRegistry {
    function proxies(address input) external view returns (address);
}

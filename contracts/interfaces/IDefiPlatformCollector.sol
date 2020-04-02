pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../lib/Defi.sol";

interface IDefiPlatformCollector {
    function getPositions(address target) external view returns (Defi.PlatformResult memory);
    function isDefiPlatformCollector() external pure returns (bool);
    function platformID() external view returns (bytes32);
}

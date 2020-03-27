pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import "./Defi.sol";

interface IDefiPlatformCollector {
    function getPositions(address target) external view returns (Defi.Position[] memory, Defi.Position[] memory);
}

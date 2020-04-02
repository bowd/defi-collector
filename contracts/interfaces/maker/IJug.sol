pragma solidity ^0.5.17;

interface IJug {
    function ilks(bytes32 ilk) external view returns (uint256 duty, uint256 rho);
}

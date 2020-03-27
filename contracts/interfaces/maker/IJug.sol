pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

interface IJug {
    function ilks(bytes32 ilk) external view returns (uint256 duty, uint256 rho);
}

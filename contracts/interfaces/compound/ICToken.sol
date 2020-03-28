pragma solidity >=0.4.25 <0.7.0;

interface ICToken {
    function getAccountSnapshot(address) external view returns (uint, uint, uint, uint);
    function balanceOfUnderlying(address) external view returns (uint);
    function getCash() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function name() external view returns (string memory);
}

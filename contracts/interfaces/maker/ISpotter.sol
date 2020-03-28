pragma solidity >=0.4.25 <0.7.0;

interface ISpotter {
    function ilks(bytes32 ilk) external view returns (address pip, uint256 mat);
}

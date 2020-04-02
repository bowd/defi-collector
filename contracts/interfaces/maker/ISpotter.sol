pragma solidity ^0.5.17;

interface ISpotter {
    function ilks(bytes32 ilk) external view returns (address pip, uint256 mat);
}

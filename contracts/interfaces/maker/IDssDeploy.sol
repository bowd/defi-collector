pragma solidity ^0.5.17;

interface IDssDeploy {
    function vat() external view returns (address);
    function spotter() external view returns (address);
    function jug() external view returns (address);
    function ilks(bytes32 ilk) external view returns (address, address);
    function dai() external view returns (address);
}

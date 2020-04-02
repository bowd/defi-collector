pragma solidity ^0.5.17;

interface IDssDeploy {
    function vat() external view returns (address);
    function spotter() external view returns (address);
    function jug() external view returns (address);
}

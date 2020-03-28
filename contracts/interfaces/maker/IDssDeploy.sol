pragma solidity >=0.4.25 <0.7.0;

interface IDssDeploy {
    function vat() external view returns (address);
    function spotter() external view returns (address);
    function jug() external view returns (address);
}

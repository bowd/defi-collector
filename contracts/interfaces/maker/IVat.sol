pragma solidity >=0.4.25 <0.7.0;

interface IVat {
    function ilks(bytes32 ilk) external view returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
    function urns(bytes32 ilk, address urn) external view returns (uint256 ink, uint256 art);
}

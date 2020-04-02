pragma solidity ^0.5.17;

interface IGetCdps {
    function getCdpsAsc(address manager, address guy) external view returns (
        uint256[] memory ids,
        address[] memory urns,
        bytes32[] memory ilks
    );
}

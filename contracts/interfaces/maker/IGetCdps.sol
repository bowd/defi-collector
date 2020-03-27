pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

interface IGetCdps {
    function getCdpsAsc(address manager, address guy) external view returns (
        uint256[] memory ids,
        address[] memory urns,
        bytes32[] memory ilks
    );
}

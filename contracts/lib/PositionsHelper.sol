pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import "./Defi.sol";

contract PositionsHelper {
    function repackPositions(Defi.Position[] memory positions, uint32 actualLength) public pure returns (Defi.Position[] memory) {
        if (positions.length > actualLength) {
            Defi.Position[] memory resizedPositions = new Defi.Position[](actualLength);
            for (uint8 i = 0; i < actualLength; i++) {
                resizedPositions[i] = positions[i];
            }
            return resizedPositions;
        }
        return positions;
    }
}

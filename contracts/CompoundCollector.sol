pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import "./IDefiPlatformCollector.sol";
import "./DependencyRegistry.sol";

import "./interfaces/compound/IPriceOracle.sol";
import "./interfaces/compound/IComptroller.sol";
import "./interfaces/compound/ICToken.sol";

contract CompoundCollector is IDefiPlatformCollector, Ownable, DependencyRegistry {
    uint8 constant IComptrollerIndex = 0;
    uint8 constant IPriceOracleIndex = 1;


    constructor(address[] memory initialDeps) DependencyRegistry(initialDeps, 2) Ownable() public {}

    function repackPositions(Defi.Position[] memory positions, uint8 actualLength) public pure returns (Defi.Position[] memory) {
        if (positions.length > actualLength) {
            Defi.Position[] memory resizedPositions = new Defi.Position[](actualLength);
            for (uint8 i = 0; i < actualLength; i++) {
                resizedPositions[i] = positions[i];
            }
            return resizedPositions;
        }
        return positions;
    }

    function hasSupply(address target, ICToken asset) internal view returns (bool) {
        uint supplyBalance = asset.balanceOfUnderlying(target);
        return supplyBalance > 0;
    }

    function hasBorrow(address target, ICToken asset) internal view returns (bool) {
        (,,uint borrowBalance,) = asset.getAccountSnapshot(target);
        return borrowBalance > 0;
    }

    function getSupply(address target, ICToken asset) internal view returns (Defi.Position memory) {
        return Defi.Position(
            abi.encode(asset),               // id
            abi.encode(asset, asset.name()), // currency
            asset.balanceOfUnderlying(target),
            asset.getCash(),
            0,
            abi.encode(asset.supplyRatePerBlock())
        );
    }

    function getBorrow(address target, ICToken asset) internal view returns (Defi.Position memory) {
        (,,uint borrowBalance,) = asset.getAccountSnapshot(target);
        return Defi.Position(
            abi.encode(asset),               // id
            abi.encode(asset, asset.name()), // currency
            borrowBalance,
            0,
            0,
            abi.encode(asset.borrowRatePerBlock())
        );
    }

    function getPositions(address target) public view returns (Defi.Position[] memory, Defi.Position[] memory) {
        IPriceOracle oracle = IPriceOracle(getDependency(IPriceOracleIndex));
        IComptroller comp = IComptroller(getDependency(IComptrollerIndex));

        address[] memory assets = comp.getAssetsIn(target);

        Defi.Position[] memory borrows = new Defi.Position[](assets.length);
        Defi.Position[] memory supplies = new Defi.Position[](assets.length);
        uint8 supplyIndex = 0;
        uint8 borrowIndex = 0;
        uint totalSupplyEth = 0;
        uint totalBorrowEth = 0;

        for (uint8 i = 0; i < assets.length; i++) {
            ICToken asset = ICToken(assets[i]);
            if (hasSupply(target, asset) == true) {
                supplies[supplyIndex] = getSupply(target, asset);
                totalSupplyEth += oracle.getUnderlyingPrice(address(asset))*supplies[supplyIndex].amount;
                supplyIndex += 1;
            }
            if (hasBorrow(target, asset) == true) {
                borrows[borrowIndex] = getBorrow(target, asset);
                totalBorrowEth += oracle.getUnderlyingPrice(address(asset))*borrows[borrowIndex].amount;
                borrowIndex += 1;
            }
        }

        uint256 colRatio;
        if (totalSupplyEth == 0) {
            colRatio = 10 ** 19;
        } else {
            colRatio = totalSupplyEth / totalBorrowEth * 100;
        }

        for (uint8 i = 0; i < borrowIndex; i++) {
            borrows[i].colRatio = colRatio;
        }

        return (
            repackPositions(borrows, borrowIndex),
            repackPositions(supplies, supplyIndex)
        );
    }
}

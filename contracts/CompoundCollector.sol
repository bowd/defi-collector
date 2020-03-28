pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/compound/IPriceOracle.sol";
import "./interfaces/compound/IComptroller.sol";
import "./interfaces/compound/ICToken.sol";

import "./IDefiPlatformCollector.sol";
import "./lib/Exponential.sol";
import "./lib/CarefulMath.sol";
import "./lib/PositionsHelper.sol";
import "./lib/DependencyRegistry.sol";

contract CompoundCollector is IDefiPlatformCollector, Ownable, DependencyRegistry, Exponential, PositionsHelper {
    bytes32 platformID_ = 0x436f6d706f756e64000000000000000000000000000000000000000000000000; // Compound
    function isDefiPlatformCollector() public pure returns (bool) { return true; }
    function platformID() public view returns (bytes32) { return platformID_; }

    uint8 constant IComptrollerIndex = 0;
    uint8 constant IPriceOracleIndex = 1;

    constructor(address[] memory initialDeps) DependencyRegistry(initialDeps, 2) Ownable() public {}

    function hasSupply(address target, address asset) internal view returns (bool) {
        return getSupplyAmount(target, asset) > 0;
    }

    function hasBorrow(address target, address asset) internal view returns (bool) {
        return getBorrowAmount(target, asset) > 0;
    }

    function getPositionID(address asset) internal pure returns (bytes memory) {
        return abi.encode(asset);
    }

    function getPositionCurrency(address asset) internal view returns (bytes memory) {
        ICToken token = ICToken(asset);
        return abi.encode(asset, token.name());
    }

    function getSupplyAmount(address target, address asset) internal view returns (uint) {
        ICToken token = ICToken(asset);
        (,uint tokenBalance,,uint exchangeRateCurrent) = token.getAccountSnapshot(target);
        Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent});
        (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, tokenBalance);
        require(mErr == MathError.NO_ERROR, "balance could not be calculated");
        return balance;
    }

    function getBorrowAmount(address target, address asset) internal view returns (uint) {
        ICToken token = ICToken(asset);

        (,,uint borrowBalance,) = token.getAccountSnapshot(target);
        return borrowBalance;
    }

    function getPoolLiquidity(address asset) internal view returns (uint) {
        ICToken token = ICToken(asset);
        return token.getCash();
    }

    function getSupplyInterestRateData(address asset) internal view returns (bytes memory) {
        ICToken token = ICToken(asset);
        return abi.encode(token.supplyRatePerBlock());
    }

    function getBorrowInterestRateData(address asset) internal view returns (bytes memory) {
        ICToken token = ICToken(asset);
        return abi.encode(token.borrowRatePerBlock());
    }

    function getSupply(address target, address asset) internal view returns (Defi.Position memory) {
        return Defi.Position(
            getPositionID(asset),
            getPositionCurrency(asset),
            getSupplyAmount(target, asset),
            getPoolLiquidity(asset),
            0,
            getSupplyInterestRateData(asset)
        );
    }

    function getBorrow(address target, address asset) internal view returns (Defi.Position memory) {
        return Defi.Position(
            getPositionID(asset),
            getPositionCurrency(asset),
            getBorrowAmount(target, asset),
            0,
            0,
            getBorrowInterestRateData(asset)
        );
    }

    function getPositions(address target) public view returns (Defi.PlatformResult memory) {
        IPriceOracle oracle = IPriceOracle(getDependency(IPriceOracleIndex));
        IComptroller comp = IComptroller(getDependency(IComptrollerIndex));

        address[] memory assets = comp.getAssetsIn(target);

        Defi.Position[] memory borrows = new Defi.Position[](assets.length);
        Defi.Position[] memory supplies = new Defi.Position[](assets.length);
        uint32 supplyIndex = 0;
        uint32 borrowIndex = 0;
        uint totalSupplyEth = 0;
        uint totalBorrowEth = 0;

        for (uint32 i = 0; i < assets.length; i++) {
            if (hasSupply(target, assets[i]) == true) {
                supplies[supplyIndex] = getSupply(target, assets[i]);
                totalSupplyEth += oracle.getUnderlyingPrice(assets[i])*supplies[supplyIndex].amount;
                supplyIndex += 1;
            }
            if (hasBorrow(target, assets[i]) == true) {
                borrows[borrowIndex] = getBorrow(target, assets[i]);
                totalBorrowEth += oracle.getUnderlyingPrice(assets[i])*borrows[borrowIndex].amount;
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

        return Defi.PlatformResult(
            platformID_,
            repackPositions(borrows, borrowIndex),
            repackPositions(supplies, supplyIndex)
        );
    }
}

pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/dydx/ISoloMargin.sol";
import "./interfaces/IERC20.sol";

import "./IDefiPlatformCollector.sol";
import "./lib/PositionsHelper.sol";
import "./lib/DependencyRegistry.sol";

contract DYDXCollector is IDefiPlatformCollector, Ownable, DependencyRegistry, PositionsHelper {
    using SafeMath for uint256;

    bytes32 platformID_ = 0x6459645800000000000000000000000000000000000000000000000000000000; // dYdX
    function isDefiPlatformCollector() public pure returns (bool) { return true; }
    function platformID() public view returns (bytes32) { return platformID_; }

    uint8 constant ISoloMarginIndex = 0;

    constructor(address[] memory initialDeps) DependencyRegistry(initialDeps, 1) Ownable() public {}

    function getPositionID(uint256 nonce, address market) internal pure returns (bytes memory) {
        return abi.encode(nonce, market);
    }

    function getPositionCurrency(address market) internal view returns (bytes memory) {
        IERC20 = token = IERC20(market);
        return abi.encode(asset, token.name());
    }

    function getPoolLiquidity(address market) internal view returns (uint) {
        IERC20 token = IERC20(market);
        return token.balanceOf(getDependency(ISoloMarginIndex));
    }

    function getSupply(address target, uint256 marketId, Types.Wei amount) internal view returns (Defi.Position memory) {
        ISoloMargin soloMargin = ISoloMargin(getDependency(ISoloMarginIndex));
        address market = soloMargin.getMarketTokenAddress(marketId);

        return Defi.Position(
            getPositionID(market),
            getPositionCurrency(market),
            amount.value,
            getPoolLiquidity(market),
            0,
            abi.encode(soloMargin.getMarketTotalPar(marketId))
        );
    }

    function getBorrow(address target, uint256 marketId, Types.Wei amount) internal view returns (Defi.Position memory) {
        return Defi.Position(
            getPositionID(asset),
            getPositionCurrency(asset),
            amount.value,
            0,
            0,
            abi.encode(soloMargin.getMarketTotalPar(marketId))
        );
    }

    function getPositions(address target) public view returns (Defi.PlatformResult memory) {
        ISoloMargin soloMargin = ISoloMargin(getDependency(ISoloMarginIndex));
        Account.Info account = Account.Info(target, 0);
        uint256 numMarkets = soloMargin.getNumMarkets();
        Defi.Position[] supplies = new Defi.Positions[](markets.length);
        Defi.Position[] borrows = new Defi.Positions[](markets.length);
        uint8 supplyIndex = 0;
        uint8 borrowIndex = 0;

        for (uint8 mi = 0; mi < numMarkets; mi++) {
            Types.Wei balance = soloMargin.getAccountWei(account, mi);
            if (balance.value != 0) {
                if (balance.sign == true) {
                    supplies[supplyIndex] = getSupply(target, mi, balance);
                    supplyIndex += 1;
                } else {
                    borrows[borrowIndex] = getBorrow(target, mi, balance);
                    borrowIndex += 1;
                }
            }
        }

        return Defi.PlatformResult(
            platformID_,
            repackPositions(borrows, borrowIndex),
            repackPositions(supplies, supplyIndex)
        );
    }
}

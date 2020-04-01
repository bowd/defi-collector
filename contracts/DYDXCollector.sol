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

    function getPositionID(uint256 nonce, uint256 marketId, address market) internal pure returns (bytes memory) {
        return abi.encode(nonce, marketId, market);
    }

    function getPositionCurrency(address market) internal view returns (bytes memory) {
        IERC20 token = IERC20(market);
        return abi.encode(token, token.name());
    }

    function getPoolLiquidity(address market) internal view returns (uint) {
        IERC20 token = IERC20(market);
        return token.balanceOf(getDependency(ISoloMarginIndex));
    }

    function getSupply(uint256 marketId, Types.Wei memory amount) internal view returns (Defi.Position memory) {
        ISoloMargin soloMargin = ISoloMargin(getDependency(ISoloMarginIndex));
        address market = soloMargin.getMarketTokenAddress(marketId);

        return Defi.Position(
            getPositionID(0, marketId, market),
            getPositionCurrency(market),
            amount.value,
            getPoolLiquidity(market),
            0,
            abi.encode(soloMargin.getMarketTotalPar(marketId))
        );
    }

    function getBorrow(uint256 marketId, Types.Wei memory amount) internal view returns (Defi.Position memory) {
        ISoloMargin soloMargin = ISoloMargin(getDependency(ISoloMarginIndex));
        address market = soloMargin.getMarketTokenAddress(marketId);

        return Defi.Position(
            getPositionID(0, marketId, market),
            getPositionCurrency(market),
            amount.value,
            0,
            0,
            abi.encode(soloMargin.getMarketTotalPar(marketId))
        );
    }

    function getPositions(address target) public view returns (Defi.PlatformResult memory) {
        ISoloMargin soloMargin = ISoloMargin(getDependency(ISoloMarginIndex));
        Account.Info memory account = Account.Info(target, 0);
        uint256 numMarkets = soloMargin.getNumMarkets();
        Defi.Position[] memory supplies = new Defi.Position[](numMarkets);
        Defi.Position[] memory borrows = new Defi.Position[](numMarkets);
        uint8 supplyIndex = 0;
        uint8 borrowIndex = 0;
        uint256 totalSupplyUSD;
        uint256 totalBorrowUSD;


        for (uint8 mi = 0; mi < numMarkets; mi++) {
            Types.Wei memory balance = soloMargin.getAccountWei(account, mi);
            if (balance.value != 0) {
                if (balance.sign == true) {
                    supplies[supplyIndex]  = getSupply(mi, balance);
                    supplyIndex += 1;
                    totalSupplyUSD += supplies[supplyIndex].amount * soloMargin.getMarketPrice(mi).value;
                } else {
                    borrows[borrowIndex] = getBorrow(mi, balance);
                    borrowIndex += 1;
                    totalBorrowUSD += borrows[borrowIndex].amount * soloMargin.getMarketPrice(mi).value;
                }
            }
        }

        uint256 colRatio = totalSupplyUSD / totalBorrowUSD;
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

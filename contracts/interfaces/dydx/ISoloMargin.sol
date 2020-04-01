pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import { Account } from "../../lib/dydx/Account.sol";
import { Monetary } from "../../lib/dydx/Monetary.sol";
import { Types } from "../../lib/dydx/Types.sol";
import { Interest } from "../../lib/dydx/Interest.sol";

interface ISoloMargin {
    function getNumMarkets() external view returns (uint256);
    function getAccountValues(Account.Info calldata account) external view returns (Monetary.Value memory, Monetary.Value memory);
    function getAccountStatus(Account.Info calldata account) external view returns (Account.Status);
    function getAccountWei(Account.Info calldata account, uint256 marketId) external view returns (Types.Wei);
    function getMarketTokenAddress(uint256 marketId) external view returns (address);
    function getMarketCurrentIndex(uint256 marketId) external view returns (Interest.Index memory);
    function getMarketInterestRate(uint256 marketId) external view returns (Interest.Rate memory);
    function getMarketTotalPar(uint256 marketId) external view returns (Types.TotalPar memory);
}


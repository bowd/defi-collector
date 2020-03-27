pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

library Defi {
    struct Position {
        bytes id;                    // encoded platform specific id for the position
        bytes currency;              // encoded platform specific currency for the position
        uint256 amount;              // total amount owed or supplied (with interest accrued)
        uint256 poolLiquidity;       // amount of currency left in pool (on supply)
        uint256 colRatio;            // ... (1e27 = 1) (where applicable) (on borrow)
        bytes interestRateData;      // data required to compute the interest rate off-chain
    }

    struct Platform {
        bytes32 id;
        Position[] borrowPositions;
        Position[] supplyPositions;
    }
}

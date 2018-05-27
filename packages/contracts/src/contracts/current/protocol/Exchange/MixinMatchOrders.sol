/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../../utils/LibBytes/LibBytes.sol";
import "./libs/LibMath.sol";
import "./libs/LibOrder.sol";
import "./libs/LibFillResults.sol";
import "./libs/LibExchangeErrors.sol";
import "./mixins/MExchangeCore.sol";
import "./mixins/MMatchOrders.sol";
import "./mixins/MSettlement.sol";
import "./mixins/MTransactions.sol";

contract MixinMatchOrders is
    LibBytes,
    LibMath,
    LibOrder,
    LibFillResults,
    LibExchangeErrors,
    MExchangeCore,
    MMatchOrders,
    MSettlement,
    MTransactions
{

    /// @dev Match two complementary orders that have a profitable spread.
    ///      Each order is filled at their respective price point. However, the calculations are
    ///      carried out as though the orders are both being filled at the right order's price point.
    ///      The profit made by the left order goes to the taker (who matched the two orders).
    /// @param leftOrder First order to match.
    /// @param rightOrder Second order to match.
    /// @param leftSignature Proof that order was created by the left maker.
    /// @param rightSignature Proof that order was created by the right maker.
    /// @return matchedFillResults Amounts filled and fees paid by maker and taker of matched orders.
    /// TODO: Make this function external once supported by Solidity (See Solidity Issues #3199, #1603)
    function matchOrders(
        Order memory leftOrder,
        Order memory rightOrder,
        bytes memory leftSignature,
        bytes memory rightSignature
    )
        public
        returns (MatchedFillResults memory matchedFillResults)
    {
        // We assume that rightOrder.takerAssetData == leftOrder.makerAssetData and rightOrder.makerAssetData == leftOrder.takerAssetData.
        // If this assumption isn't true, the match will fail at signature validation.
        rightOrder.takerAssetData = leftOrder.makerAssetData;
        rightOrder.makerAssetData = leftOrder.takerAssetData;

        // Get left & right order info
        OrderInfo memory leftOrderInfo = getOrderInfo(leftOrder);
        OrderInfo memory rightOrderInfo = getOrderInfo(rightOrder);

        // Fetch taker address
        address takerAddress = getCurrentContextAddress();

        // Either our context is valid or we revert
        assertValidMatch(leftOrder, rightOrder);

        // Compute proportional fill amounts
        matchedFillResults = calculateMatchedFillResults(
            leftOrder,
            rightOrder,
            leftOrderInfo.orderTakerAssetFilledAmount,
            rightOrderInfo.orderTakerAssetFilledAmount
        );

        // Ensure match results are valid
        // assertValidMatchResults(matchedFillResults);

        // Validate fill contexts
        assertValidFill(
            leftOrder,
            leftOrderInfo,
            takerAddress,
            matchedFillResults.left.takerAssetFilledAmount,
            matchedFillResults.left.takerAssetFilledAmount,
            leftSignature
        );
        assertValidFill(
            rightOrder,
            rightOrderInfo,
            takerAddress,
            matchedFillResults.right.takerAssetFilledAmount,
            matchedFillResults.right.takerAssetFilledAmount,
            rightSignature
        );

        // Settle matched orders. Succeeds or throws.
        settleMatchedOrders(
            leftOrder,
            rightOrder,
            takerAddress,
            matchedFillResults
        );

        // Update exchange state
        updateFilledState(
            leftOrder,
            takerAddress,
            leftOrderInfo.orderHash,
            leftOrderInfo.orderTakerAssetFilledAmount,
            matchedFillResults.left
        );
        updateFilledState(
            rightOrder,
            takerAddress,
            rightOrderInfo.orderHash,
            rightOrderInfo.orderTakerAssetFilledAmount,
            matchedFillResults.right
        );

        return matchedFillResults;
    }

    /// @dev Validates context for matchOrders. Succeeds or throws.
    /// @param leftOrder First order to match.
    /// @param rightOrder Second order to match.
    function assertValidMatch(
        Order memory leftOrder,
        Order memory rightOrder
    )
        internal
        view
    {
        // Make sure there is a profitable spread.
        // There is a profitable spread iff the cost per unit bought (OrderA.MakerAmount/OrderA.TakerAmount) for each order is greater
        // than the profit per unit sold of the matched order (OrderB.TakerAmount/OrderB.MakerAmount).
        // This is satisfied by the equations below:
        // <leftOrder.makerAssetAmount> / <leftOrder.takerAssetAmount> >= <rightOrder.takerAssetAmount> / <rightOrder.makerAssetAmount>
        // AND
        // <rightOrder.makerAssetAmount> / <rightOrder.takerAssetAmount> >= <leftOrder.takerAssetAmount> / <leftOrder.makerAssetAmount>
        // These equations can be combined to get the following:
        require(
            safeMul(leftOrder.makerAssetAmount, rightOrder.makerAssetAmount) >=
            safeMul(leftOrder.takerAssetAmount, rightOrder.takerAssetAmount),
            encodeErrorBytes32Bytes32(
                uint8(ExchangeError.NEGATIVE_SPREAD_REQUIRED),
                getOrderHash(leftOrder),
                getOrderHash(rightOrder)
            )
        );
    }

    /// @dev Validates matched fill results. Succeeds or throws.
    /// @param matchedFillResults Amounts to fill and fees to pay by maker and taker of matched orders.
    // function assertValidMatchResults(MatchedFillResults memory matchedFillResults)
    //     internal
    //     pure
    // {
    //     // If the amount transferred from the left order is different than what is transferred, it is a rounding error amount.
    //     // Ensure this difference is negligible by dividing the values with each other. The result should equal to ~1.
    //     uint256 leftMakerAssetFilledAmount = safeAdd(
    //         matchedFillResults.right.takerAssetFilledAmount,
    //         matchedFillResults.leftMakerAssetSpreadAmount
    //     );
    //     require(
    //         !isRoundingError(
    //             matchedFillResults.left.makerAssetFilledAmount,
    //             leftMakerAssetFilledAmount,
    //             1
    //         ),
    //         encodeError(uint8(ExchangeError.ROUNDING_ERROR))
    //     );

    //     // If the amount transferred from the right order is different than what is transferred, it is a rounding error amount.
    //     // Ensure this difference is negligible by dividing the values with each other. The result should equal to ~1.
    //     require(
    //         !isRoundingError(
    //             matchedFillResults.right.makerAssetFilledAmount,
    //             matchedFillResults.left.takerAssetFilledAmount,
    //             1
    //         ),
    //         encodeError(uint8(ExchangeError.ROUNDING_ERROR))
    //     );
    // }

    /// @dev Calculates fill amounts for the matched orders.
    ///      Each order is filled at their respective price point. However, the calculations are
    ///      carried out as though the orders are both being filled at the right order's price point.
    ///      The profit made by the leftOrder order goes to the taker (who matched the two orders).
    /// @param leftOrder First order to match.
    /// @param rightOrder Second order to match.
    /// @param leftOrderTakerAssetFilledAmount Amount of left order already filled.
    /// @param rightOrderTakerAssetFilledAmount Amount of right order already filled.
    /// @param matchedFillResults Amounts to fill and fees to pay by maker and taker of matched orders.
    function calculateMatchedFillResults(
        Order memory leftOrder,
        Order memory rightOrder,
        uint256 leftOrderTakerAssetFilledAmount,
        uint256 rightOrderTakerAssetFilledAmount
    )
        internal
        pure
        returns (MatchedFillResults memory matchedFillResults)
    {
        // We settle orders at the exchange rate of the right order.
        // The amount saved by the left maker goes to the taker.
        // Either the left or right order will be fully filled; possibly both.
        // The left order is fully filled iff the right order can sell more than left can buy.
        // That is: the amount required to fill the left order is less than or equal to
        //          the amount we can spend from the right order:
        //          <leftTakerAssetAmountRemaining> <= <rightTakerAssetAmountRemaining> * <rightMakerToTakerRatio>
        //          <leftTakerAssetAmountRemaining> <= <rightTakerAssetAmountRemaining> * <rightOrder.makerAssetAmount> / <rightOrder.takerAssetAmount>
        //          <leftTakerAssetAmountRemaining> * <rightOrder.takerAssetAmount> <= <rightTakerAssetAmountRemaining> * <rightOrder.makerAssetAmount>
        uint256 rightTakerAssetAmountRemaining = safeSub(rightOrder.takerAssetAmount, rightOrderTakerAssetFilledAmount);
        uint256 leftTakerAssetAmountRemaining = safeSub(leftOrder.takerAssetAmount, leftOrderTakerAssetFilledAmount);
        uint256 leftTakerAssetFilledAmount;
        uint256 rightTakerAssetFilledAmount;
        if (
            safeMul(leftTakerAssetAmountRemaining, rightOrder.takerAssetAmount) <=
            safeMul(rightTakerAssetAmountRemaining, rightOrder.makerAssetAmount)
        ) {
            // Left order will be fully filled: maximally fill left
            leftTakerAssetFilledAmount = leftTakerAssetAmountRemaining;

            // The right order receives an amount proportional to how much was spent.
            // TODO: Can we ensure rounding error is in the correct direction?
            rightTakerAssetFilledAmount = getPartialAmount(
                rightOrder.takerAssetAmount,
                rightOrder.makerAssetAmount,
                leftTakerAssetFilledAmount
            );
        } else {
            // Right order will be fully filled: maximally fill right
            rightTakerAssetFilledAmount = rightTakerAssetAmountRemaining;

            // The left order receives an amount proportional to how much was spent.
            // TODO: Can we ensure rounding error is in the correct direction?
            leftTakerAssetFilledAmount = getPartialAmount(
                rightOrder.makerAssetAmount,
                rightOrder.takerAssetAmount,
                rightTakerAssetFilledAmount
            );
        }

        // Calculate fill results for left order
        matchedFillResults.left = calculateFillResults(
            leftOrder,
            leftTakerAssetFilledAmount
        );

        // Calculate fill results for right order
        matchedFillResults.right = calculateFillResults(
            rightOrder,
            rightTakerAssetFilledAmount
        );

        // Calculate amount given to taker
        matchedFillResults.leftMakerAssetSpreadAmount = safeSub(
            matchedFillResults.left.makerAssetFilledAmount,
            matchedFillResults.right.takerAssetFilledAmount
        );

        // Return fill results
        return matchedFillResults;
    }
}

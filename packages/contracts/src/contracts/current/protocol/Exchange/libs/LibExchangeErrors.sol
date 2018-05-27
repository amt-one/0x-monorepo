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

import "../../../utils/LibErrorEncoder/LibErrorEncoder.sol";

contract LibExchangeErrors is
    LibErrorEncoder
{

    // General Exchange error codes
    enum ExchangeError {
    
        /// Order validation errors ///
        ORDER_UNFILLABLE,          // Order cannot be filled. (uint8 orderStatus, bytes32 orderHash)
        INVALID_MAKER,             // Invalid makerAddress. (bytes32 orderHash)
        INVALID_TAKER,             // Invalid takerAddress. (bytes32 orderHash)
        INVALID_SENDER,            // Invalid `msg.sender`. (bytes32 orderHash)
        INVALID_ORDER_SIGNATURE,   //
        ASSET_DATA_MISMATCH,       // Asset data must be the same for each order. (bytes32 orderHash)
        
        /// fillOrder validation errors ///
        INVALID_TAKER_AMOUNT,      // takerAssetFillAmount cannot equal 0. (bytes32 orderHash)
        ROUNDING_ERROR,            // Rounding error greater than 0.1% of takerAssetFillAmount. (uint256 takerAssetFilledAmount, bytes32 orderHash)
        
        /// Signature validation errors ///
        INVALID_SIGNATURE,         // Signature validation failed. (byte32 orderHash)
        SIGNATURE_ILLEGAL,         // Signature type is illegal.
        SIGNATURE_UNSUPPORTED,     // Signature type unsupported.
        
        /// cancelOrdersUptTo errors ///
        INVALID_NEW_MAKER_EPOCH,   // Specified salt must be greater than or equal to existing makerEpoch. (uint256 oldMakerEpoch)

        /// fillOrKillOrder errors ///
        COMPLETE_FILL_FAILED,      // Desired takerAssetFillAmount could not be completely filled. (bytes32 orderHash)

        /// matchOrders errors ///
        POSITIVE_SPREAD_REQUIRED,  // Matched orders must have a negative spread.

        /// Transaction errors ///
        REENTRANCY_ILLEGAL,        // (bytes32 transactionHash)
        INVALID_TX_HASH,           // Transaction has already been executed. (bytes32 transactionHash)
        INVALID_TX_SIGNATURE,      //
        FAILED_EXECUTION,          // Transaction execution failed. (bytes32 transactionHash)
        
        /// registerAssetProxy errors ///
        ASSET_PROXY_MISMATCH,      // oldAssetProxy proxy does not match currentAssetProxy. (address currentAssetProxy)
        ASSET_PROXY_ID_MISMATCH,   // newAssetProxyId does not match given assetProxyId.

        /// Length validation errors ///
        LENGTH_GT_0_REQUIRED,      // Signature must have a length greater than 0.
        LENGTH_1_REQUIRED,         // Signature must have a length of 1.
        LENGTH_66_REQUIRED         // Signature must have a length of 66.
    }
}

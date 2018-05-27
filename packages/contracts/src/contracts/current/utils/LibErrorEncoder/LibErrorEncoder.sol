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

contract LibErrorEncoder {

    /// @dev Encodes an error code as a string.
    /// @param err Error code.
    /// @return Error code encoded as string.
    function encodeError(uint8 err)
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(err));
        return result;
    }

    /// @dev Encodes an error code and bytes32 as a string.
    /// @param err Error code.
    /// @param a 32 byte argument.
    /// @return Error code tightly packed with bytes32 and encoded as string.
    function encodeErrorBytes32(
        uint8 err,
        bytes32 a
    )
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(
            err,
            a
        ));
        return result;
    }

    /// @dev Encodes an error code, bytes1, and bytes32 as a string.
    /// @param err Error code.
    /// @param a 1 byte argument.
    /// @param b 32 byte argument.
    /// @return Error code tightly packed with bytes1, bytes32, and encoded as string.
    function encodeErrorBytes1Bytes32(
        uint8 err,
        bytes1 a,
        bytes32 b
    )
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(
            err,
            a,
            b
        ));
        return result;
    }

    /// @dev Encodes an error code, bytes1, and bytes32 as a string.
    /// @param err Error code.
    /// @param a 32 byte argument.
    /// @param b 32 byte argument.
    /// @return Error code tightly packed with bytes32, bytes32, and encoded as string.
    function encodeErrorBytes32Bytes32(
        uint8 err,
        bytes32 a,
        bytes32 b
    )
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(
            err,
            a,
            b
        ));
        return result;
    }

    /// @dev Encodes an error code and bytes32 as a string.
    /// @param err Error code.
    /// @param a 20 byte argument.
    /// @return Error code tightly packed with bytes20 and encoded as string.
    function encodeErrorBytes20(
        uint8 err,
        bytes20 a
    )
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(
            err,
            a
        ));
        return result;
    }
}

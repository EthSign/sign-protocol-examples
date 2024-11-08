// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Groth16Verifier } from "./Verifier.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ISPHook } from "@ethsign/sign-protocol-evm/src/interfaces/ISPHook.sol";

contract SHA256PreimageVerifier is Groth16Verifier, Ownable {
    address public spInstance;

    constructor() Ownable(_msgSender()) { }

    function setSPInstance(address instance) external onlyOwner {
        spInstance = instance;
    }
}

// @dev This contract implements the actual schema hook.
contract ZKHook is ISPHook, SHA256PreimageVerifier {
    error Unsupported();
    error ZKVerificationFailed();

    function didReceiveAttestation(
        address, // attester
        uint64, // schemaId
        uint64, // attestationId
        bytes calldata extraData
    )
        external
        payable
    {
        if (_msgSender() != spInstance) revert Unsupported();
        (uint256[2] memory _pA, uint256[2][2] memory _pB, uint256[2] memory _pC, uint256[32] memory _pubSignals) =
            abi.decode(extraData, (uint256[2], uint256[2][2], uint256[2], uint256[32]));
        // If the SHA256 preimage proof verification fails, revert.
        if (!verifyProof(_pA, _pB, _pC, _pubSignals)) revert ZKVerificationFailed();
    }

    function didReceiveAttestation(
        address, // attester
        uint64, // schemaId
        uint64, // attestationId
        IERC20, // resolverFeeERC20Token
        uint256, // resolverFeeERC20Amount
        bytes calldata // extraData
    )
        external
        pure
    {
        revert Unsupported();
    }

    function didReceiveRevocation(
        address, // attester
        uint64, // schemaId
        uint64, // attestationId
        bytes calldata // extraData
    )
        external
        payable
    {
        revert Unsupported();
    }

    function didReceiveRevocation(
        address, // attester
        uint64, // schemaId
        uint64, // attestationId
        IERC20, // resolverFeeERC20Token
        uint256, // resolverFeeERC20Amount
        bytes calldata // extraData
    )
        external
        pure
    {
        revert Unsupported();
    }
}

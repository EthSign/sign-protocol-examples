// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISP } from "@ethsign/sign-protocol-evm/src/interfaces/ISP.sol";
import { Attestation } from "@ethsign/sign-protocol-evm/src/models/Attestation.sol";

contract DelegateAttest is Ownable {
    ISP public spInstance;

    constructor() Ownable(_msgSender()) { }

    function setSPInstance(address instance) external onlyOwner {
        spInstance = ISP(instance);
    }

    function createAttestation(Attestation calldata att, string calldata indexingKey, bytes calldata delegationSignature, bytes calldata extraData) external returns (uint64) {
        uint64 attestationId = spInstance.attest(att, indexingKey, delegationSignature, extraData);
        return attestationId;
    }
}
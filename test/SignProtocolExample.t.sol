// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { WhitelistHook } from "../src/02-schema-hook/WhitelistHook.sol";
import { SP } from "@ethsign/sign-protocol-evm/src/core/SP.sol";
import { ISP } from "@ethsign/sign-protocol-evm/src/interfaces/ISP.sol";
import { Schema } from "@ethsign/sign-protocol-evm/src/models/Schema.sol";
import { DataLocation } from "@ethsign/sign-protocol-evm/src/models/DataLocation.sol";
import { Attestation } from "@ethsign/sign-protocol-evm/src/models/Attestation.sol";

/**
 * @title SignProtocolExample
 * @notice Reference implementation for Sign Protocol integration
 * @dev Demonstrates basic schema registration and attestation creation
 */
contract SignProtocolExample is Test {
    // ============ Storage ============
    ISP public sp;
    WhitelistHook public whitelistHook;
    uint64 public schemaId;

    address public constant EXAMPLE_ATTESTER = 0x55D22d83752a9bE59B8959f97FCf3b2CAbca5094;

    /**
     * @notice Set up the test environment
     * @dev Deploys SP, initializes WhitelistHook, and registers schema
     */
    function setUp() external {
        sp = new SP();
        SP(address(sp)).initialize(1, 1);

        whitelistHook = new WhitelistHook();
        whitelistHook.setWhitelist(EXAMPLE_ATTESTER, true);

        Schema memory schema = _createSchema();
        schemaId = sp.register(schema, "");
    }

    /**
     * @notice Test the basic attestation flow
     * @dev Creates and verifies a simple attestation
     */
    function test_attestationFlow() external {
        bytes memory data = encodeData("exampleId", "exampleField", block.timestamp);

        Attestation memory attestation = _createAttestation(data);

        vm.prank(EXAMPLE_ATTESTER);
        uint64 attestationId = sp.attest(attestation, "example", "", "");

        _verifyAttestation(attestationId);
    }

    /**
     * @notice Creates a schema definition
     * @return Schema memory The created schema
     */
    function _createSchema() internal view returns (Schema memory) {
        return Schema({
            registrant: address(this),
            revocable: true,
            dataLocation: DataLocation.ONCHAIN,
            maxValidFor: 0,
            hook: whitelistHook,
            timestamp: 0,
            data: _getSchemaData()
        });
    }

    /**
     * @notice Creates an attestation with the given data
     * @param data The encoded attestation data
     * @return Attestation memory The created attestation
     */
    function _createAttestation(bytes memory data) internal view returns (Attestation memory) {
        return Attestation({
            schemaId: schemaId,
            linkedAttestationId: 0,
            attestTimestamp: 0,
            revokeTimestamp: 0,
            data: data,
            attester: EXAMPLE_ATTESTER,
            validUntil: uint64(block.timestamp + 1 days),
            dataLocation: DataLocation.ONCHAIN,
            revoked: false,
            recipients: new bytes[](0)
        });
    }

    /**
     * @notice Verifies an attestation's data
     * @param attestationId The ID of the attestation to verify
     */
    function _verifyAttestation(uint64 attestationId) internal view {
        Attestation memory storedAttestation = sp.getAttestation(attestationId);
        (string memory id, string memory field, uint256 timestamp) = decodeData(storedAttestation.data);

        assertEq(id, "exampleId");
        assertEq(field, "exampleField");
        assertEq(timestamp, block.timestamp);
    }

    /**
     * @notice Returns the schema data definition
     * @return string memory The schema data in JSON format
     */
    function _getSchemaData() internal pure returns (string memory) {
        return "{\"name\":\"ExampleSchema\",\"data\":[{\"name\":\"id\",\"type\":\"string\"},"
        "{\"name\":\"field\",\"type\":\"string\"},{\"name\":\"timestamp\",\"type\":\"uint256\"}]}";
    }

    /**
     * @notice Encodes the attestation data
     * @param id The ID field
     * @param field The example field
     * @param timestamp The timestamp
     * @return bytes memory The encoded data
     */
    function encodeData(string memory id, string memory field, uint256 timestamp) public pure returns (bytes memory) {
        return abi.encode(id, field, timestamp);
    }

    /**
     * @notice Decodes the attestation data
     * @param data The encoded data
     * @return tuple containing decoded id, field, and timestamp
     */
    function decodeData(bytes memory data) public pure returns (string memory, string memory, uint256) {
        return abi.decode(data, (string, string, uint256));
    }
}

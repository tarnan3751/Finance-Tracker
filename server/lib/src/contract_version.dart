/// The contract version the server implements, reported by `GET /health`. A test holds it
/// equal to `info.version` in `api/openapi.yaml`, so a contract change without a server
/// change fails the gate.
library;

/// `info.version` of the contract this server implements.
const contractVersion = '0.3.0';

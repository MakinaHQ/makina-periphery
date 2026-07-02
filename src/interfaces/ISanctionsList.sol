// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ISanctionsList {
    event SanctionsCheckStatusChanged(bool indexed enabled);

    /// @notice Address of the Chainalysis sanctions oracle used for screening.
    function sanctionsOracle() external view returns (address);

    /// @notice True if sanctions screening is enabled, false otherwise.
    function isSanctionsCheckEnabled() external view returns (bool);

    /// @notice Enables or disables sanctions screening.
    /// @param enabled True to enable screening, false to disable.
    function setSanctionsCheckStatus(bool enabled) external;
}

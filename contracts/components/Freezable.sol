// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.24;

import '../libraries/LibConstants.sol';
import '../interfaces/MFreezable.sol';
import './MainStorage.sol';

abstract contract Freezable is
    MainStorage,
    LibConstants,
    MFreezable
{
    event LogFrozen();
    event LogUnFrozen();

    function isFrozen() public view override returns (bool) {
        return stateFrozen;
    }

    function validateFreezeRequest(uint256 requestTime) internal override {
        require(requestTime != 0, 'FORCED_ACTION_UNREQUESTED');
        // Verify timer on escape request.
        uint256 freezeTime = requestTime + FREEZE_GRACE_PERIOD;

        // Prevent wraparound.
        assert(freezeTime >= FREEZE_GRACE_PERIOD);
        require(block.timestamp >= freezeTime, 'FORCED_ACTION_PENDING'); // NOLINT: timestamp.

        // Forced action requests placed before freeze, are no longer valid after the un-freeze.
        require(freezeTime > unFreezeTime, 'REFREEZE_ATTEMPT');
    }

    function freeze() internal override notFrozen {
        unFreezeTime = block.timestamp + UNFREEZE_DELAY;

        // Update state.
        stateFrozen = true;

        // Log event.
        emit LogFrozen();
    }

    // TODO: add modifier onlyGovernance
    function unFreeze() external onlyFrozen  {
        require(block.timestamp >= unFreezeTime, 'UNFREEZE_NOT_ALLOWED_YET');

        // Update state.
        stateFrozen = false;

        // Increment roots to invalidate them, w/o losing information.
        // validiumVaultRoot += 1;

        // Log event.
        emit LogUnFrozen();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library Operators {
    bytes32 public constant OPERATORS_SLOT = bytes32(uint256(keccak256("river.state.operators")) - 1);

    bytes32 public constant OPERATORS_MAPPING_SLOT = bytes32(uint256(keccak256("river.state.operatorsMapping")) - 1);

    struct Operator {
        bool active;
        string name;
        address operator;
        uint256 limit;
        uint256 funded;
        uint256 keys;
        uint256 stopped;
    }

    struct CachedOperator {
        bool active;
        string name;
        address operator;
        uint256 limit;
        uint256 funded;
        uint256 keys;
        uint256 stopped;
        uint256 index;
    }

    struct OperatorResolution {
        bool active;
        uint256 index;
    }

    struct SlotOperator {
        Operator[] value;
    }

    struct SlotOperatorMapping {
        mapping(string => OperatorResolution) value;
    }

    error OperatorNotFound(string name);
    error OperatorNotFoundAtIndex(uint256 index);

    function _getOperatorIndex(string memory name) internal view returns (uint256) {
        bytes32 slot = OPERATORS_MAPPING_SLOT;

        SlotOperatorMapping storage opm;

        assembly {
            opm.slot := slot
        }

        if (opm.value[name].active == false) {
            revert OperatorNotFound(name);
        }

        return opm.value[name].index;
    }

    function _getOperatorActive(string memory name) internal view returns (bool) {
        bytes32 slot = OPERATORS_MAPPING_SLOT;

        SlotOperatorMapping storage opm;

        assembly {
            opm.slot := slot
        }
        return opm.value[name].active;
    }

    function _setOperatorIndex(
        string memory name,
        bool active,
        uint256 index
    ) internal {
        bytes32 slot = OPERATORS_MAPPING_SLOT;

        SlotOperatorMapping storage opm;

        assembly {
            opm.slot := slot
        }
        opm.value[name] = OperatorResolution({active: active, index: index});
    }

    function exists(string memory name) internal view returns (bool) {
        return _getOperatorActive(name);
    }

    function indexOf(string memory name) internal view returns (int256) {
        bytes32 slot = OPERATORS_MAPPING_SLOT;

        SlotOperatorMapping storage opm;

        assembly {
            opm.slot := slot
        }

        if (opm.value[name].active == false) {
            return -1;
        }

        return int256(opm.value[name].index);
    }

    function get(string memory name) internal view returns (Operator storage) {
        bytes32 slot = OPERATORS_SLOT;
        uint256 index = _getOperatorIndex(name);

        SlotOperator storage r;

        assembly {
            r.slot := slot
        }

        return r.value[index];
    }

    function getByIndex(uint256 index) internal view returns (Operator storage) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        assembly {
            r.slot := slot
        }

        if (r.value.length <= index) {
            revert OperatorNotFoundAtIndex(index);
        }

        return r.value[index];
    }

    function getCount() internal view returns (uint256) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        assembly {
            r.slot := slot
        }

        return r.value.length;
    }

    function _hasFundableKeys(Operators.Operator memory operator) internal pure returns (bool) {
        return (operator.active &&
            operator.keys > operator.funded - operator.stopped &&
            operator.limit > operator.funded - operator.stopped);
    }

    function getAllActive() internal view returns (Operator[] memory) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        assembly {
            r.slot := slot
        }

        uint256 activeCount = 0;

        for (uint256 idx = 0; idx < r.value.length; ++idx) {
            if (r.value[idx].active == true) {
                ++activeCount;
            }
        }

        Operator[] memory activeOperators = new Operator[](activeCount);

        uint256 activeIdx = 0;
        for (uint256 idx = 0; idx < r.value.length; ++idx) {
            if (r.value[idx].active == true) {
                activeOperators[activeIdx] = r.value[idx];
                ++activeIdx;
            }
        }

        return activeOperators;
    }

    function getAllFundable() internal view returns (CachedOperator[] memory) {
        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        assembly {
            r.slot := slot
        }

        uint256 activeCount = 0;

        for (uint256 idx = 0; idx < r.value.length; ++idx) {
            if (_hasFundableKeys(r.value[idx])) {
                ++activeCount;
            }
        }

        CachedOperator[] memory activeOperators = new CachedOperator[](activeCount);

        uint256 activeIdx = 0;
        for (uint256 idx = 0; idx < r.value.length; ++idx) {
            Operator memory op = r.value[idx];
            if (_hasFundableKeys(op)) {
                activeOperators[activeIdx] = CachedOperator({
                    active: op.active,
                    name: op.name,
                    operator: op.operator,
                    limit: op.limit,
                    funded: op.funded,
                    keys: op.keys,
                    stopped: op.stopped,
                    index: idx
                });
                ++activeIdx;
            }
        }

        return activeOperators;
    }

    function set(string memory name, Operator memory newValue) internal returns (uint256) {
        bool opExists = _getOperatorActive(name);

        bytes32 slot = OPERATORS_SLOT;

        SlotOperator storage r;

        assembly {
            r.slot := slot
        }

        if (opExists == false) {
            r.value.push(newValue);
            _setOperatorIndex(name, newValue.active, r.value.length - 1);
            return (r.value.length - 1);
        } else {
            uint256 index = _getOperatorIndex(name);
            r.value[index] = newValue;
            if (opExists != newValue.active) {
                _setOperatorIndex(name, newValue.active, index);
            }
            return (index);
        }
    }
}

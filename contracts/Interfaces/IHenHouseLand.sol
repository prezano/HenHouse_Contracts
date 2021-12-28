// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

abstract contract IHenHouseLand {
    enum Capacity {
        SMALL,
        MEDIUM,
        LARGE
    }

    struct HenHouseLand {
        Capacity capacity;
        uint256[10] chickensInside;
        bool isForSale;
        uint256 price;
    }
}
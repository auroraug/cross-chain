// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from './IERC20.sol';

interface IERC20CrossChain is IERC20 {
    function transferRemote(
        string calldata destinationChain,
        address destinationAddress,
        address recipent,
        uint256 amount
    ) external payable;
}

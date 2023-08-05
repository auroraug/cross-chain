// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAxelarGateway } from 'https://github.com/auroraug/alt/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from 'https://github.com/auroraug/alt/interfaces/IAxelarGasService.sol';
import { IERC20CrossChain } from 'https://github.com/auroraug/alt/interfaces/IERC20CrossChain.sol';
import { ERC20 } from 'https://github.com/auroraug/alt/ERC20.sol';
import { AxelarExecutable } from 'https://github.com/auroraug/alt/AxelarExecutable.sol';
import { Upgradable } from 'https://github.com/auroraug/alt/Upgradable.sol';
import { StringToAddress, AddressToString } from 'https://github.com/auroraug/alt/AddressString.sol';

contract ERC20CrossChain is AxelarExecutable, ERC20, Upgradable, IERC20CrossChain {
    using StringToAddress for string;
    using AddressToString for address;

    error AlreadyInitialized();

    event FalseSender(string sourceChain, string sourceAddress);

    IAxelarGasService public immutable gasService;
// Gateway Contract:   0xe432150cce91c13a887f7D836923d5597adD8E31
// Gas Service Contract:  0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6

    constructor(
        address gateway_,
        address gasReceiver_,
        uint8 decimals_
    ) AxelarExecutable(gateway_) ERC20('Cross Token', 'CT', decimals_) {
        gasService = IAxelarGasService(gasReceiver_);
    }

    function _setup(bytes calldata params) internal override {
        (string memory name_, string memory symbol_) = abi.decode(params, (string, string));
        if (bytes(name).length != 0) revert AlreadyInitialized();
        name = name_;
        symbol = symbol_;
    }

    // This is for testing.
    function giveMe(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function transferRemote(
        string calldata destinationChain,
        address destinationAddress,
        uint256 amount
    ) public payable override {
        require(msg.value > 0, 'Gas payment is required');

        
        _burn(msg.sender, amount);
        bytes memory payload = abi.encode(msg.sender, amount);
        // bytes memory payload = abi.encode(destinationAddress, amount);
        string memory stringAddress = destinationAddress.toString();
        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            destinationChain,
            stringAddress,
            payload,
            msg.sender
        );
        gateway.callContract(destinationChain, stringAddress, payload);
    }

    function _execute(
        string calldata, /*sourceChain*/
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        // if (sourceAddress.toAddress() != address(this)) {
        //     emit FalseSender(sourceAddress, sourceAddress);
        //     return;
        // }
        (address to, uint256 amount) = abi.decode(payload, (address, uint256));
        _mint(to, amount);
    }

    function contractId() external pure returns (bytes32) {
        return keccak256('example');
    }
}

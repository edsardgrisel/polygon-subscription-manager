// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StableCoin is ERC20 {
    uint256 public constant MINT_AMOUNT = 100000;
    uint256 public constant DECIMALS = 6;

    constructor() ERC20("Mock Tether", "USDT") {}

    function mint() public {
        _mint(msg.sender, MINT_AMOUNT * (10 ** DECIMALS));
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OrderbookExchange is ERC2771Context {
    using SafeERC20 for ERC20;

    event Exchanged(bytes32 indexed o1ID, bytes32 indexed o2ID, uint256 amount);

    address private immutable tkna;
    address private immutable tknb;
    address private immutable defender;

    struct Order {
        bytes32 oID;
        address user;
        address sellToken;
        address buyToken;
        uint256 sellAmount;
        uint256 buyAmount;
        uint256 deadline;
    }

    constructor(
        MinimalForwarder forwarder,
        address _tkna,
        address _tknb
    ) ERC2771Context(address(forwarder)) {
        tkna = _tkna;
        tknb = _tknb;
        defender = msg.sender;
    }

    // non reentrant
    function exchange(
        Order calldata o1,
        Order calldata o2,
        bytes memory signature1,
        bytes memory signature2
    ) external {
        require(o1.buyToken == tkna || o1.buyToken == tknb, "Invalid token");
        require(o1.sellToken == tkna || o1.sellToken == tknb, "Invalid token");

        require(
            o1.buyToken != o1.sellToken,
            "Invalid order, same buy and sell token"
        );

        require(o2.buyToken == tkna || o2.buyToken == tknb, "Invalid token");
        require(o2.sellToken == tkna || o2.sellToken == tknb, "Invalid token");

        require(
            o2.buyToken != o2.sellToken,
            "Invalid order, same buy and sell token"
        );

        require(
            o1.deadline >= block.timestamp && o2.deadline >= block.timestamp,
            "Invalid deadline"
        );

        require(
            o1.buyToken == o2.sellToken && o1.sellToken == o2.buyToken,
            "Invalid tokens, tokens don't match"
        );

        require(
            o1.buyAmount == o2.sellAmount && o1.sellAmount == o2.buyAmount,
            "Invalid amounts"
        );

        address _defender = _verify(o1, signature1);
        require(defender == _defender, "Invalid signature");

        _defender = _verify(o2, signature2);
        require(defender == _defender, "Invalid signature");

        ERC20(o1.sellToken).safeTransferFrom(o1.user, o2.user, o1.sellAmount);
        ERC20(o2.sellToken).safeTransferFrom(o2.user, o1.user, o2.sellAmount);

        emit Exchanged(o1.oID, o2.oID, o1.buyAmount);
    }

    function approveSpending(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(token == tkna || token == tknb, "Invalid token");
        address owner = _msgSender();

        require(owner != address(0), "Invalid owner");

        IERC20Permit(token).permit(
            owner,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function _hash(Order calldata order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.oID,
                    order.user,
                    order.sellToken,
                    order.buyToken,
                    order.sellAmount,
                    order.buyAmount,
                    order.deadline
                )
            );
    }

    function _verify(
        Order calldata order,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 digest = _hash(order);
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(digest), signature);
    }
}

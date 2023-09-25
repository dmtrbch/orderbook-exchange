# Offchain Orderbook Exchange Using Gassless transactions

## Project Description

Decentralized Application that allows users to swap TKNA for TKNB and vice versa in a p2p manner.

NOTE: Orders are stored on a centralized server and not on the blockchain, the Ethereum blokchain is only used for approvals and conducting the swap.

Users are only signing approvals, the order is signed by the OZ relayer.

## Project Workflow

1. User connects a wallet in the Frontend Dapp
2. Signs an approval (unlimited) in order for the exchange to be able to transfer tokens (sell tokens) on his behalf
3. After signing an approval the user is present with interface to place an order
4. When placing an order this order is not added on the blockchain it is added in a centralized server
5. With the use of OpenZeppelin Defender (Relayer and Autotask) the offchain script will check if there is a matching order (quotient of buy and sell amount)
6. If there is a match the relayer will sign two orders, if the amounts for the orders are same, both of the orders will be completed, if not one order will be completed and one order will be partially filled
8. The Relayer will always signs orders with same amounts, it will split the bigger order on smaller chunks.
9. On-chain we must check that the orders are signed by the Relayer and not by anyone else, since we can only accept orders from our trusted party
10. In the ```OrderbookExchange.sol``` smart there are multiple checks to see if the orders can be processed, if everything pass the swap is conducted with the use of ERC20 transferFrom method
11. If the transfer of tokens was succsuccessful, ```Exchanged``` event will be emitted, this is important for our offchain orderbook. In case an order is only partially filled (which will be the case most of the times), we need the emitted event in order to be able to updated the order that was partially filled, subtract the transferred amount from it. For example we will notify the Frontend dapp that ```Order #2323 is 70% completed```


## Project Architecture

- Two ```ERC20Permit``` tokens, TokenA & TokenB
- ```OrderbookExchange.sol``` contract that inherits from ```ERC2771Context```, with two functions ```approveSpending()``` used for approving the exchange to be able to swap tokens on users behalf, ```exchange()``` used for transffering the sell tokens from UserA to UserB and vice versa.
- Openzeppeling Defender using a Relayer and Autotask. Together Relayer, Autotaks and the exchange contract inheriting from ```ERC2771Context``` are used for implementing gassless transactions ```ERC2771```
- React Frontend dapp, used as interfance for users to be able to sign offchain approvals and place orders.
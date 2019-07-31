# Contract PIDEX

*A contract designed to handle order of an Exchange*

## setPiOrder(address receiving, uint price) external payable returns (bytes32)

Function used to set orders of the pair PI/token (token of address *receiving*) with a price *price*. The sending PI amount is indicated in the transfering tx.value. The function returns the ID of the order.

> piDex.methods.setPiOrder(receiving, price).send({from: account, value: piAmount, gas: gasLimit})

## cancelOrder (bytes32 orderId)

Function used to cancel an order with ID *orderId*. If the order is still open, not cancelled and not dealed the order can be cancelled. The contract transfers back the amount of the order in the same transaction (atomic procedure). Note that the transaction HAS TO be originated from the account who owns the order.

>piDex.methods.cancelOrder(orderId).send({from: account, gas: gasLimit})
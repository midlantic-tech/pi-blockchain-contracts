# Contrat ManageNodes.sol

* A contract designed to handle nodes' market*

## purchaseNode()

Function used to buy the next available node. The tx.value MUST be the exact price to buy the node or the tx will revert. The price include the 1% commission. Note that this extra 1% is going to be sent to *EmisorContract.sol* (retired of circulating) in the same transaction (is an atomic procedure).

> manageNodes.methods.purchaseNode().send({from: account, value: price, gas: gasLimit})
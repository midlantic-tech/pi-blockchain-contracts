# Contrat ManageNodes.sol

*A contract designed to handle nodes' market*

## purchaseNode ()

Function used to buy the next available node. The tx.value HAS TO be the exact price to buy the node or the tx will revert. The price include the 1% commission. Note that this extra 1% is going to be sent to *EmisorContract.sol* (retired of circulating to increase PI's value) in the same transaction (is an atomic procedure).

> manageNodes.methods.purchaseNode().send({from: account, value: price, gas: gasLimit})

## sellNode ()

Function used to sell a node owned by the sender of the transaction. The sell price is the node's value less 1% commission. The contract transfers sell price to the sender of the transaction and the commission to *EmisorContract* all in the same transaction (atomic procedure).

> manageNodes.methods.sellNode().send({from: account, gas: gasLimit})

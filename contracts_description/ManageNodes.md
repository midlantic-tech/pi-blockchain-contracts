## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| contracts/validators/interfaces/ManageNodes.sol | 9dba9277a996fb28b8070fb6d1a36bfd867e5f2c |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **ManageNodes** | Implementation |  |||
| └ | \<Constructor\> | Public ❗️ | 🛑  | |
| └ | setValidatorSetAddress | Public ❗️ | 🛑  |NO❗️ |
| └ | getNodes | Public ❗️ |   |NO❗️ |
| └ | getNodesValue | Public ❗️ |   |NO❗️ |
| └ | getPayedPrice | Public ❗️ |   |NO❗️ |
| └ | purchaseNode | External ❗️ |  💵 | isNotNode |
| └ | sellNode | Public ❗️ | 🛑  | isNode |
| └ | changeValidatorsPending | Public ❗️ | 🛑  | isNode isNotNode |
| └ | changeValidatorsExecute | External ❗️ |  💵 | isNode isNotNode |
| └ | withdrawRest | Public ❗️ | 🛑  |NO❗️ |
| └ | updateValidatorPrice | Internal 🔒 | 🛑  | |
| └ | removeFromArray | Internal 🔒 | 🛑  | |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |

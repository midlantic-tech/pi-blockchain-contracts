pragma solidity 0.5.0;

import "./ManageNodes.sol";
import "../blockrewards/PiChainBlockReward.sol";
import "../dex/PIDEX.sol";
import "../tokens/IRC223.sol";
import "../tokens/IERC20.sol";
import "../tokens/ERC223_receiving_contract.sol";
import "../utils/safeMath.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title Contract designed to manage a Pool for a node

contract NodePool is IRC223, IERC20, Owned {
    using SafeMath for uint;
    using SafeMath for int;

    struct FunctionVars {
        int m;
        int b;
    }

    ManageNodes manageNodes;
    PiChainBlockReward nodeRewards;

    mapping(address => uint) public balances;
    mapping(uint => uint) public intervalReward;
    mapping(address => uint) public intervalByMember;
    mapping(address => bool) public sellVoted;
    mapping(uint => uint) public associatedPercentages;
    mapping(uint => FunctionVars) public functions;

    //ERC20
    string private _name;
    string private _symbol;
    uint8 _decimals;
    uint public totalSupply;
    address public dexAddress;

    //NODE
    bool public bought;
    uint public interval;
    uint public assigned;

    //SELL
    uint public wannaSell;
    bool public sold;
    uint public soldPrice;
    uint public nodePricePercentage;
    uint[] public pricesArray;
    uint public sellAmountWithdrawl;

    //PERCENTAGE

    modifier onlyMember {
        require(balances[msg.sender] > 0);
        _;
    }

    modifier onlyWhenBought {
        require(bought);
        _;
    }

    modifier onlyWhenSold {
        require(sold);
        _;
    }

    modifier onlyWhenNotBought {
        require(!bought);
        _;
    }

    event PurchaseNode(uint price);
    event NodeRewards(uint indexed interval, uint rewards, address sender);
    event MemberRewards(uint indexed fromInterval, uint indexed toInterval, uint toPay, address indexed sender);
    event VoteSell(address indexed sender, uint balance, uint wannaSell);
    event VoteNotSell(address indexed sender, uint balance, uint wannaSell);
    event SellWithdrawl(address indexed sender, uint amount);
    event SellNode(uint nodeValue, uint currentPercentage, uint requiredPercentage);
    event DeadContract(address killer);

    constructor(uint[] memory prices, uint[] memory percentages, uint _nodePricePercentage, address dex, string memory name, string memory symbol) public {
        manageNodes = ManageNodes(address(0x0000000000000000000000000000000000000012));
        nodeRewards = PiChainBlockReward(address(0x0000000000000000000000000000000000000009));
        dexAddress = dex;
        _decimals = 18;
        _name = name;
        _symbol = symbol;
        pricesArray = prices;
        for (uint i = 0; i < pricesArray.length; i++){
            associatedPercentages[pricesArray[i]] = percentages[i];
        }
        nodePricePercentage = _nodePricePercentage;
    }

    /// @dev Payable function to receive funds
    function () external payable {

    }

    /// @dev Function to see the contract's balance in PI
    /// return uint Contract's balance
    function contractBalance() public view returns(uint) {
        return address(this).balance;
    }

    /// @dev Function for the owner to withdrawl funds if can't buy the node
    function withdrawlFunds() public onlyOwner onlyWhenNotBought {
        msg.sender.transfer(address(this).balance);
    }

    //ERC20

    /// @dev Get the name
    /// @return _name name of the token
    function name() public view returns (string memory){
        return _name;
    }

    /// @dev Get the symbol
    /// @return _symbol symbol of the token
    function symbol() public view returns (string memory){
        return _symbol;
    }

    /// @dev Get the number of decimals
    /// @return _symbol number of decimals of the token
    function decimals() public view returns (uint8){
        return _decimals;
    }

    /// @dev Get balance of an account
    /// @param _user account to return the balance of
    /// @return balances[_user] balance of the account
    function balanceOf(address _user) public view returns (uint balance) {
        return balances[_user];
    }

    /// @dev Set an order of token in an exchange
    /// @param _value amount of token for the order
    /// @param receiving address of the token to buy (address(0) when buying PI)
    /// @param exchangeAddress address of the exchange to set the order
    function setDexOrder(uint _value, address receiving, uint price, uint side, address exchangeAddress)
        public
        onlyWhenBought
        returns(bytes32)
    {
        require(balances[msg.sender] >= _value, "No balance");
        address _to = address(exchangeAddress);
        address payable _from = msg.sender;
        uint codeLength;
        bytes memory empty;
        bytes32 orderId;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        payOffMember(_to, _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            PIDEX dex = PIDEX(_to);
            orderId = dex.setTokenOrder(_from, _value, receiving, price, side);
        }
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value, empty);

        return orderId;
    }

    /// @dev Transfer token and pay off rewards, interval and sell vote of both parties
    /// @param _to account receiving the token
    /// @param _value amount of token to send
    function transfer(address _to, uint _value) public onlyWhenBought {
        payOffMember(_to, _value);

        _transfer(_to, msg.sender,_value);
    }

    /// @dev Transfer token
    /// @param _to account receiving the token
    /// @param _from account sending the token
    /// @param _value amount of token to send
    function _transfer(address _to, address payable _from, uint _value) internal {
        require(balances[_from] >= _value, "No balance");
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value);
        }
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value, empty);
    }

    //NODE

    /// @dev Function to purchase the node in ManageNodes contract
    function purchaseNode() public onlyOwner onlyWhenNotBought {
        uint price = manageNodes.purchaseNodePrice();
        manageNodes.purchaseNode.value(price)();
        bought = true;
        totalSupply = price;
        balances[msg.sender] = totalSupply;
        msg.sender.transfer(address(this).balance);
        calculateFunctions(price);
        emit PurchaseNode(price);
    }

    /// @dev Function to withdrawl the rewards of the node and store in the contract
    /// @param fromDay Used when the rewards haven't been withdrawl for a long time
    function withdrawlNodeRewards(uint fromDay) public onlyMember onlyWhenBought {
        nodeRewards.withdrawRewards(fromDay);
        intervalReward[interval] = address(this).balance.sub(assigned);
        assigned = assigned.add(intervalReward[interval]);
        interval++;
        emit NodeRewards(interval.sub(1), intervalReward[interval.sub(1)], msg.sender);
    }

    function seeNodeRewards(uint fromDay) public view onlyMember onlyWhenBought returns (uint) {
        return nodeRewards.seeRewards(fromDay);
    }

    function withdrawlMemberRewards(uint userInterval) public onlyMember onlyWhenBought {
        require(interval > intervalByMember[msg.sender]);
        uint fromInterval = intervalByMember[msg.sender];

        if (userInterval > fromInterval) {
            fromInterval = userInterval;
        }

        uint toPay = 0;
        for(uint i = fromInterval; i < interval; i++) {
            toPay = toPay.add(intervalReward[i].mul(balances[msg.sender]).div(totalSupply));
        }

        intervalByMember[msg.sender] = interval;
        assigned = assigned.sub(toPay);

        if (msg.sender != dexAddress) {
            msg.sender.transfer(toPay);
        }

        emit MemberRewards(fromInterval, interval, toPay, msg.sender);
    }

    function seeMemberRewards(uint userInterval) public view onlyMember onlyWhenBought returns(uint) {
        uint fromInterval = intervalByMember[msg.sender];
        uint toPay = 0;

        if (interval > intervalByMember[msg.sender]){
            if (userInterval > fromInterval) {
                fromInterval = userInterval;
            }

            for(uint i = fromInterval; i < interval; i++) {
                toPay = toPay.add(intervalReward[i].mul(balances[msg.sender]).div(totalSupply));
            }
        }

        return toPay;
    }

    function withdrawlSellPrice() public onlyMember onlyWhenSold {
        msg.sender.transfer(soldPrice.mul(balances[msg.sender]).div(totalSupply));
        sellAmountWithdrawl = sellAmountWithdrawl.add(balances[msg.sender]);
        emit SellWithdrawl(msg.sender, soldPrice.mul(balances[msg.sender]).div(totalSupply));
        balances[msg.sender] = 0;

        if (sellAmountWithdrawl == totalSupply) {
            emit DeadContract(msg.sender);
        }
    }

    //SELL
    function getWannaSell() public view returns (uint) {
        return wannaSell.mul(100 ether).div(totalSupply);
    }

    function voteSell() public onlyMember onlyWhenBought {
        require(!sellVoted[msg.sender]);
        wannaSell = wannaSell.add(balances[msg.sender]);
        sellVoted[msg.sender] = true;
        checkSell();
        emit VoteSell(msg.sender, balances[msg.sender], wannaSell);
    }

    function voteNotSell() public onlyMember onlyWhenBought {
        require(sellVoted[msg.sender]);
        wannaSell = wannaSell.sub(balances[msg.sender]);
        sellVoted[msg.sender] = false;
        emit VoteNotSell(msg.sender, balances[msg.sender], wannaSell);
    }

    function getRequiredPercentage() public view returns (uint, uint) {
        uint nodeValue = manageNodes.sellNodePrice();
        uint requiredPercentage;
        uint priceInterval;

        if (nodeValue > pricesArray[pricesArray.length - 1]) {
            nodeValue = pricesArray[pricesArray.length - 1];
        } else if (nodeValue < pricesArray[0]) {
            nodeValue = pricesArray[0];
        }

        for (uint i = 0; i < pricesArray.length.sub(1); i++) {
            if (nodeValue > pricesArray[i]) {
                priceInterval = i;
            }
        }

        requiredPercentage = uint(functions[priceInterval].m.mul(int(nodeValue)).div(1 ether).add(functions[priceInterval].b));

        uint currentPercentage = wannaSell.mul(100 ether).div(totalSupply);

        return (requiredPercentage, currentPercentage);
    }

    function getRequiredPercentageForValue(uint nodeValue) public view returns (uint, uint) {
        uint requiredPercentage;
        uint priceInterval;

        if (nodeValue > pricesArray[pricesArray.length - 1]) {
            nodeValue = pricesArray[pricesArray.length - 1];
        } else if (nodeValue < pricesArray[0]) {
            nodeValue = pricesArray[0];
        }

        for (uint i = 0; i < pricesArray.length.sub(1); i++) {
            if (nodeValue > pricesArray[i]) {
                priceInterval = i;
            }
        }

        requiredPercentage = uint(functions[priceInterval].m.mul(int(nodeValue)).div(1 ether).add(functions[priceInterval].b));

        uint currentPercentage = wannaSell.mul(100 ether).div(totalSupply);

        return (requiredPercentage, currentPercentage);
    }

    function checkSell() public onlyMember onlyWhenBought {
        uint nodeValue = manageNodes.sellNodePrice();
        uint requiredPercentage;
        uint priceInterval;

        if (nodeValue > pricesArray[pricesArray.length - 1]) {
            nodeValue = pricesArray[pricesArray.length - 1];
        } else if (nodeValue < pricesArray[0]) {
            nodeValue = pricesArray[0];
        }

        for (uint i = 0; i < pricesArray.length.sub(1); i++) {
            if (nodeValue > pricesArray[i]) {
                priceInterval = i;
            }
        }

        requiredPercentage = uint(functions[priceInterval].m.mul(int(nodeValue)).div(1 ether).add(functions[priceInterval].b));

        uint currentPercentage = wannaSell.mul(100 ether).div(totalSupply);

        if (currentPercentage >= requiredPercentage) {
            sellNode();
            emit SellNode(nodeValue, currentPercentage, requiredPercentage);
        }
    }

    function sellNode() internal {
        uint price = manageNodes.sellNodePrice();
        manageNodes.sellNode();
        sold = true;
        soldPrice = price;
    }

    function payOffMember(address _to, uint _value) internal {
        if (interval > intervalByMember[msg.sender]) {
            withdrawlMemberRewards(intervalByMember[msg.sender]);
        }

        if (sellVoted[msg.sender]) {
            wannaSell = wannaSell.sub(_value);
        }

        if (sellVoted[_to]) {
            wannaSell = wannaSell.add(_value);
        }

        intervalByMember[_to] = interval;
        intervalByMember[msg.sender] = interval;
    }

    function calculateFunctions(uint nodePrice) internal { //CAMBIAR A INTERNAL
        pricesArray.push(nodePrice);
        associatedPercentages[nodePrice] = nodePricePercentage;
        pricesArray = sort(pricesArray);
        for (uint i = 0; i < pricesArray.length.sub(1); i++) {
            (functions[i].m, functions[i].b) = calculateVars(
                pricesArray[i],
                associatedPercentages[pricesArray[i]],
                pricesArray[i+1],
                associatedPercentages[pricesArray[i+1]]
            );
        }
    }

    function calculateVars(uint x1, uint y1, uint x2, uint y2) internal pure returns (int, int) {
        int m = (int(y2).sub(int(y1))).mul(1 ether).div((int(x2).sub(int(x1))));
        int b = m.mul((int(x1))).div(1 ether);
        b = int(y1).sub(b);
        return (m, b);
    }

    function sort(uint[] memory data) internal returns(uint[] memory) {
       quickSort(data, int(0), int(data.length - 1));
       return data;
    }

    function quickSort(uint[] memory arr, int left, int right) internal {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }
}

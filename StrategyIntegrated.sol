pragma solidity >=0.4.0;
pragma experimental ABIEncoderV2;

//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



// Given a client address, check if it exists in our clients, replace requires with this check --done
// Decision to be made on clients reinvesting in the same strategy --done

// Do we need any other confirmation before setting start_time and end_time?
// Set binanceStratAccount and fundAccount
// calculate fees and transfer to our address
// decide when we shall deduct 2% initial  
// Run solidity static analysis


// Investment doesn't expire until the user says so
// Multiple investments can be made to the strategy, regardless of if a previous investment period has ended or not

// Implement accepting of usdt
// Sending

//check if amount os approved before calling transferFrom


// 1st - 500 month 1 -> 
// 2nd - 500 month 2 -> 

// Main => management

contract StrategyIntegrated {
    
    using SafeMath for uint; 
    
     cftoken;
    
    address public fund_manager;
    string strategyName; 
    uint min_amt;
    int256 min_return;
    bool status = true; //True => active

    address binanceStratAccount;//change
    address fundAccount = 0x058E4741d78B60185aaDa1129D19baB7b9949962;
    
    // Should we remove an investment if end trade has been reached;
    mapping (address => mapping(uint => Investment)) public investments;
    mapping (address => uint) investmentLength;
    mapping (address => uint[]) activeInvestments;
    address[] clientList;
    
    event EndTrade(address, uint, Investment);
    event TradingResult(address, uint, Investment);
    
    struct Investment {
        uint amt;
        uint256 duration;
        uint256 start_time;
        uint256 end_time;
        uint256 tradeResults;
	    uint fees;
        bool trading;
        bool withdrawal;
        uint8 flag;
    }
    
    modifier onlyManager(){
            require(msg.sender == fund_manager, "Only Fund Manager can call this");
            _;
    }

    //constructor -- making it payable to add ETH to be used as Gas to cover Provable query costs
    constructor(address _tokenContract, address _binanceAccount, string memory _strategyName, uint _min_amt, int256 _min_return) public {
        fund_manager = msg.sender;
        cftoken = ERC20(_tokenContract); 
        
        binanceStratAccount = _binanceAccount;
        strategyName = _strategyName;
        min_amt = _min_amt;
        min_return = _min_return;
    }
    
    function transfer(address _to, uint256 _value) onlyManager public {
       cftoken.transfer(_to, _value);
       //To transfer tokens from THIS CONTRACT address
      
    }
    
    function transferFrom(address _from, address _to, uint256 _value) onlyManager public returns (bool success){
        cftoken.transferFrom(_from, _to, cftoken.allowance(_from, _to));
        //Works only after approve has been called from the _from address with _to adress being approved
    }
    
    // function approve(uint256 _value) public{
    //     //This allows this CONTRACT to withdraw tokens from some other address
    //     cftoken.approve(address(this), _value);
    // }
    
    function balanceof(address adr) public returns(uint){
        //TO check balance.. What else do you want?
        return cftoken.balanceOf(adr);
    }
    
    function getFundManager() external view returns(address){
        return fund_manager;
    }

    function getContractBalance() external view returns(uint bal){
        return address(this).balance;
    }
    
    function addGas() public payable returns(uint gas){
        return msg.value;
    }
    
    function updateMinimumAmount(uint _min_amt) onlyManager external{
        min_amt = _min_amt;
    }
    
    function updateMinimumReturn(int _min_return) onlyManager external{
        min_return = _min_return;
    }
    
    function updateStatus(bool _status) onlyManager external{
        status = _status;
    }

    function setClient(address _clientAdd, uint256 _duration) external {
        // Check for usdt
        
        require(status == true, "This Strategy is not currently active.");//
        require(cftoken.allowance(_clientAdd, address(this)) >= min_amt, "Please invest more than the minimum value");
        require(balanceof(_clientAdd) >= cftoken.allowance(_clientAdd, address(this)), "You do not have sufficient funds to invest");
        
        uint approvedAmount = cftoken.allowance(_clientAdd, address(this));
        
        cftoken.transferFrom(_clientAdd, address(this), approvedAmount);
        //it should revert if this transferFrom fails.
        
        uint newIndex;
        uint transferableAmount;
        uint initialFees;
        
       
        
    if((investmentLength[_clientAdd] == 0)) {
            clientList.push(_clientAdd);
            newIndex = 1;
            investmentLength[_clientAdd] = 1;
        }
        else{
            newIndex = investmentLength[_clientAdd] + 1;
            investmentLength[_clientAdd] = newIndex;
        }
        
        transferableAmount =approvedAmount.sub((approvedAmount.mul(2)).div(100));
        initialFees = (approvedAmount.mul(2)).div(100);
        
        transferFunds( transferableAmount, initialFees );
        
	   
        investments[_clientAdd][newIndex].start_time = block.timestamp;
        investments[_clientAdd][newIndex].duration = _duration;
        investments[_clientAdd][newIndex].amt = transferableAmount;
        investments[_clientAdd][newIndex].end_time = investments[_clientAdd][newIndex].start_time.add(investments[_clientAdd][newIndex].duration);
        investments[_clientAdd][newIndex].trading = true;
        investments[_clientAdd][newIndex].flag = 1;
        
    }
    
     // confirm if the address actually exists?
    function transferFunds(uint transferableAmount, uint initialFees) private {
        //binanceStratAccount.transfer(transferableAmount);
        //fundAccount.transfer(initialFees);
        
        cftoken.transfer(binanceStratAccount, transferableAmount);
        cftoken.transfer(fundAccount, initialFees);
    }
    
    function getClients() onlyManager external view returns(address[] memory){
        return clientList;
    }
    
    function getActiveInvestments(address _adrs) external view returns(Investment[] memory){
        require(msg.sender == _adrs || msg.sender == fund_manager, "You do not have access");//
        Investment[] memory activeInvestments;
        uint a=0;
        for(uint i; i<investmentLength[_adrs]; i++){
            if(investments[_adrs][i].trading == true){
                activeInvestments[a]=investments[_adrs][i];
                a++;
            }
        }
        return activeInvestments;
    }
    
    // function getActiveInvestmentIds(address _adrs) external view returns(uint[] memory){
    //     require(msg.sender == _adrs || msg.sender == fund_manager, "You do not have access");
    //     uint[] memory ids;
    //     uint a=0;
    //     for(uint i; i<investmentLength[_adrs]; i++){
    //         if(investments[_adrs][i].trading == true){
    //             ids[a]=i;
    //             a++;
    //         }
    //     }
    // }
    
    // function getInvestmentPerId(address _adrs, uint id) external view returns(Investment memory){
    //     require(msg.sender == _adrs || msg.sender == fund_manager, "You do not have access");
    //     return investments[_adrs][id];
    // }
   
    // again, check if the address is valid and call from cron job
    function end_trade(address _clientAdd, uint _index) public {
        require(msg.sender == _clientAdd || msg.sender == fund_manager);//, "You do not have access"
        
        require(investments[_clientAdd][_index].flag == 1, "This client does not exist");// "This client does not exist"
        require(investments[_clientAdd][_index].trading == true, "You do not have any active investments");//
        //emit EndTrade(_clientAdd, _index, investments[_clientAdd][_index]);
    }
    
    function setResults(address _clientAdd, uint _index, int256 _results) onlyManager external  {
        
        if(investments[_clientAdd][_index].trading != false) { //is it necessary as we are already checking in end_trade
            uint result = 0;
            uint amount = investments[_clientAdd][_index].amt;
            if(_results > min_return) //profit 5% to deduct fees, change it based on start_time and end_time
            {
                uint res =  (amount.mul(uint(_results)).div(10000)); //fees set to 20% of profit
                investments[_clientAdd][_index].fees = uint((res.mul(20)).div(100));
                result = amount.add(uint((res.mul(80)).div(100))); 
            } else if(_results > 0 && _results <= min_return) {
                result = amount.add((amount.mul(uint(_results))).div(10000));
            } else {
                result = amount.sub((amount.mul(uint(_results))).div(10000));
            }
            investments[_clientAdd][_index].tradeResults = result;
            investments[_clientAdd][_index].withdrawal = true;
        }
        //emit ClientInvestments(_clientAdd, _index);
    }

    function emitClientInvestments(address _clientAdd, uint _index) private {
        //emit TradingResult(_clientAdd, _index, investments[_clientAdd][_index]);
    }
    
    function getTradingResult (address _clientAdd, uint _index) view public returns(uint) {
        require(msg.sender == _clientAdd || msg.sender == fund_manager, "You do not have access");//
        return investments[_clientAdd][_index].tradeResults;
    }
    
    function withdraw(address _clientAdd, uint _index) onlyManager external {
        
        uint payableAmount;
        require(investments[_clientAdd][_index].withdrawal != false, "tradeResults is not set, run setResults() first");
        //if(investments[_clientAdd][_index].trading != false) { //is it necessary as we are already checking in end_trade
           // require(investments[_clientAdd][_index].tradeResults > 0, "Trade Result is  not set");//
            payableAmount = investments[_clientAdd][_index].tradeResults;
            investments[_clientAdd][_index].trading = false;
       // }
        
        //require(address(this).balance > (payableAmount.add(investments[_clientAdd][_index].fees)), "Sufficient funds not available");
        require(balanceof(address(this)) > (payableAmount.add(investments[_clientAdd][_index].fees)), "Sufficient funds not available");//
        
        //address payable payableClientAddress = payable(_clientAdd);
        //payableClientAddress.transfer(payableAmount);
        //fundAccount.transfer(investments[_clientAdd][_index].fees);
        
        transfer(_clientAdd, payableAmount);
        transfer(fundAccount, investments[_clientAdd][_index].fees);
    }
}
//toke

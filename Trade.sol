 pragma solidity ^0.4.8;

import "./CFT.sol";
//Import the token(s) contract(s) which we want to handle here
//Important obseration is that IERC20 wont work for all ERC20 tokens
//Only those tokens that inherit from IERC20 can be interacted with, by using IERC20 contract
//Dai does not inherit IERC20 as you can see it in it's contract so we are importing the Dai source code directly

contract Trade{
    //This contract will work like a DEX alowing us to interact with tokens that we define
    CFT cftoken;
    address public Manager;
    
    
    constructor(address tokenContract) public payable{
      Manager = msg.sender;
      cftoken = CFT(tokenContract);  
    }
    function transfer(address _to, uint256 _value) public payable{
        //dai.approve(0x064103ffD68f9F7410Cebd236Dc49a568CC5fde8, 100000000000000000000);
        //dai.transferFrom(0x064103ffD68f9F7410Cebd236Dc49a568CC5fde8, 0xb571F795Dc9DdEE032a05238Ee96ee7B8a9B20aD, 10000000000000000000);
        cftoken.transfer(_to, _value);
    }
    function transferFrom(address _to, uint256 _value) public payable returns (bool success){
        //dai.approve(0x064103ffD68f9F7410Cebd236Dc49a568CC5fde8, 100000000000000000000);
        //dai.transferFrom(0x064103ffD68f9F7410Cebd236Dc49a568CC5fde8, 0xb571F795Dc9DdEE032a05238Ee96ee7B8a9B20aD, 10000000000000000000);
        cftoken.transferFrom(msg.sender, _to, _value);
    }
    function approve(uint256 amt) public{
        //No use unless we can run transferFrom function...
        cftoken.approve(address(this), amt);
    }
    function balanceof(address adr) public payable returns(uint){
        
        return cftoken.balanceOf(adr);
    }
    
        
    //My Test_Acc: 0xb571F795Dc9DdEE032a05238Ee96ee7B8a9B20aD --ignore
}

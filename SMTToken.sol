pragma solidity ^0.4.10;

import './SafeMath.sol';
import './Ownable.sol';
import './Pausable.sol';
import './Sales.sol';


contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract SMTToken is Token,Ownable,Sales {
    string public constant name = "Sun Money Token";
    string public constant symbol = "SMT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    ///The value to be sent to our BTC address
    uint public valueToBeSent = 1;
    ///The ethereum address of the person manking the transaction
    address personMakingTx;
    //uint private output1,output2,output3,output4;
    ///to return the address just for the testing purposes
    address public addr1;
    ///to return the tx origin just for the testing purposes
    address public txorigin;

    //function for testing only btc address
    bool isTesting;
    ///testing the name remove while deploying
    bytes32 testname;
    address finalOwner;
    bool public finalizedPublicICO = false;
    bool public finalizedPreICO = false;

    uint256 public SMTfundAfterPreICO;
    uint256 public ethraised;
    uint256 public btcraised;

    bool public istransferAllowed;

    uint256 public constant SMTfund = 10 * (10**6) * 10**decimals; 
    uint256 public fundingStartBlock; // crowdsale start block
    uint256 public fundingEndBlock; // crowdsale end block
    uint256 public  tokensPerEther = 150; //TODO
    uint256 public  tokensPerBTC = 22*150*(10**10);
    uint256 public tokenCreationMax= 72* (10**5) * 10**decimals; //TODO
    mapping (address => bool) ownership;


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
      if(!istransferAllowed) throw;
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    //this is the default constructor
    function SMTToken(uint256 _fundingStartBlock, uint256 _fundingEndBlock){
        totalSupply = SMTfund;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }


    ICOSaleState public salestate = ICOSaleState.PrivateSale;

    ///**To be replaced  the following by the following*///
    /**

    **/

    /***Event to be fired when the state of the sale of the ICO is changes**/
    event stateChange(ICOSaleState state);

    /**

    **/
    function setState(ICOSaleState state)  returns (bool){
    if(!ownership[msg.sender]) throw;
    salestate = state;
    stateChange(salestate);
    return true;
    }

    /**

    **/
    function getState() returns (ICOSaleState) {
    return salestate;

    }



    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
        if(!istransferAllowed) throw;
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function addToBalances(address _person,uint256 value) {
        if(!ownership[msg.sender]) throw;
        balances[_person] = SafeMath.add(balances[_person],value);

    }

    function addToOwnership(address owners) onlyOwner{
        ownership[owners] = true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if(!istransferAllowed) throw;
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      if(!istransferAllowed) throw;
      return allowed[_owner][_spender];
    }

    function increaseEthRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        ethraised+=value;
    }

    function increaseBTCRaised(uint256 value){
        if(!ownership[msg.sender]) throw;
        btcraised+=value;
    }




    function finalizePreICO(uint256 value) returns(bool){
        if(!ownership[msg.sender]) throw;
        finalizedPreICO = true;
        SMTfundAfterPreICO =value;
        return true;
    }


    function finalizePublicICO() returns(bool) {
        if(!ownership[msg.sender]) throw;
        finalizedPublicICO = true;
        istransferAllowed = true;
        return true;
    }


    function isValid() returns(bool){
        if(block.number>=fundingStartBlock && block.number<fundingEndBlock ){
            return true;
        }else{
            return false;
        }
    }

    ///do not allow payments on this address

    function() payable{
        throw;
    }
}


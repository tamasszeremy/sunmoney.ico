pragma solidity ^0.4.10;
import './SMTToken.sol';
import './Pausable.sol';
import './BTC.sol';
import './Utils.sol';
import './SafeMath.sol';
import './PricingStrategyPublic.sol';
import './Ownable.sol';
import './Sales.sol';

contract PublicICO is Ownable,Pausable,PricingStrategyPublic,Utils,Sales{

    SMTToken token;
    uint256 public tokensPerUSD;
    uint256 public tokensPerBTC;
    uint public tokensPerEther;
    uint256 public initialSupply;
    uint256 public currentSupply;

    uint256 public startDate;///the date in unix timestamp

    uint256 public endDate;//the date in unix timestamp

    function changeStartDate(uint256 _new) public onlyOwner{
        startDate = _new;
    }

    function changeEndDate(uint256 _new) public onlyOwner{
        endDate = _new;
    }

    uint256  public numberOfBackers;
    /* Max investment count when we are still allowed to change the multisig address */
    ///the txorigin is the web3.eth.coinbase account
    //record Transactions that have claimed ether to prevent the replay attacks
    //to-do
    mapping(uint256 => bool) transactionsClaimed;
    uint256 public valueToBeSent;
    uint public investorCount;

    uint public maxTokenpublic;

    uint256 public tokenCreationMax;


    function changeMaxTokenPublic(uint256 _new) public onlyOwner{
        
    }
    ///the event log to log out the address of the multisig wallet
    event logaddr(address addr);

    //the constructor function
   function PublicICO(address tokenAddress){
        //require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input
        token = SMTToken(tokenAddress);
        tokensPerEther = token.tokensPerEther();
        tokensPerBTC = token.tokensPerBTC();
        valueToBeSent = token.valueToBeSent();
        maxTokenpublic = token.tokenCreationMax()-token.SMTfundAfterPreICO();
        tokenCreationMax =  token.tokenCreationMax()-token.SMTfundAfterPreICO();
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    /**
        Payable function to send the ether funds
    **/
    event logstate(ICOSaleState state);
    ////Here we will put up our payable function
    ////for the ethers 

    function() external payable stopInEmergency{
        bool  isValid = isValidSale();
       if(!isValid) throw;
       if (msg.value == 0) throw;
        // ICOSaleState currentState = getStateFunding();
       // if(currentState==ICOSaleState.Failed) throw;
       if(initialSupply>tokenCreationMax) throw;
       uint256 totalTokens;
       totalTokens =calNewTokens(msg.value,"ethereum");
       initialSupply = SafeMath.add(initialSupply,totalTokens);
       maxTokenpublic = SafeMath.sub(maxTokenpublic,totalTokens);
       token.addToBalances(msg.sender,totalTokens);
       Transfer(token,msg.sender,totalTokens);
       token.increaseEthRaised(msg.value);
       numberOfBackers++;
    }


    ///a function using safemath to work with
    ///the new function
    function calNewTokens(uint256 contribution,string types) returns (uint256){
        uint256 disc = totalDiscount(currentSupply,contribution,types);
        uint256 CreatedTokens;
        if(keccak256(types)==keccak256("ethereum")) CreatedTokens = SafeMath.mul(contribution,tokensPerEther);
        else if(keccak256(types)==keccak256("bitcoin"))  CreatedTokens = SafeMath.mul(contribution,tokensPerBTC);
        uint256 tokens = SafeMath.add(CreatedTokens,SafeMath.div(SafeMath.mul(CreatedTokens,disc),100));
        return tokens;
    }
    
    function tokenAssignExchange(address addr,uint256 value,uint256 txHash) external onlyOwner returns(bool){
         bool  isValid = isValidSale();
        if(!isValid) throw;
        if (value == 0) throw;
        if(transactionsClaimed[txHash]) throw;
         // ICOSaleState currentState = getStateFunding();
        // if(currentState==ICOSaleState.Failed) throw;
        if(initialSupply>tokenCreationMax) throw;
        uint256 totalTokens;
        totalTokens =calNewTokens(value,"ethereum");
        initialSupply = SafeMath.add(initialSupply,totalTokens);
        maxTokenpublic = SafeMath.sub(maxTokenpublic,totalTokens);
        token.addToBalances(addr,totalTokens);
        Transfer(token,addr,totalTokens);
        token.increaseEthRaised(value);
        numberOfBackers++;
        transactionsClaimed[txHash] = true;
        return true;
    }

    //Token distribution for the case of the ICO
    ///function to run when the transaction has been veified
    function processTransaction(bytes txn, uint256 txHash,address addr,bytes20 btcaddr) onlyOwner returns (uint)
    {
        bool  valueSent;
        bool  isValid = isValidSale();
        if(!isValid) throw;
     // ICOSaleState currentState = getStateFunding();

        if(!transactionsClaimed[txHash]){
            var (a,b) = BTC.checkValueSent(txn,btcaddr,valueToBeSent);
            if(a){
                valueSent = true;
                transactionsClaimed[txHash] = true;
                 ///since we are creating tokens we need to increase the total supply
               allottTokensBTC(addr,b);
        return 1;
        }
            }

    }
    
    ///function to allot tokens to address
    function allottTokensBTC(address addr,uint256 value) internal{
        // ICOSaleState currentState = getStateFunding();
        if(initialSupply>tokenCreationMax) throw;
        uint256 totalTokens;
        totalTokens =calNewTokens(value,"bitcoin");
        initialSupply = SafeMath.add(initialSupply,totalTokens);
        maxTokenpublic = SafeMath.sub(maxTokenpublic,totalTokens);
        token.addToBalances(addr,totalTokens);
        Transfer(token,addr,totalTokens);
        numberOfBackers++;
        token.increaseBTCRaised(value);
    }

    function finalizeTokenSale() public onlyOwner{
        token.finalizePublicICO();
    }

    function isValidSale() public returns (bool) {
        if(now>=startDate && now<endDate){
            return true;
        }else{
            return false;
        }
    }




    

}
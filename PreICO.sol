    pragma solidity ^0.4.10;
import './SMTToken.sol';
import './Pausable.sol';
import './BTC.sol';
import './Utils.sol';
import './SafeMath.sol';
import './PricingStrategy.sol';
import './Ownable.sol';
import './Sales.sol';

contract PreICO is Ownable,Pausable, Utils,PricingStrategy,Sales{

	SMTToken token;
	uint256 public tokensPerBTC;
	uint public tokensPerEther;
	uint256 public initialSupplyPrivateSale;
	uint256 public initialSupplyPreSale;
	uint256 public SMTfundAfterPreICO;
	uint256 public initialSupplyPublicPreICO;
	uint256 public currentSupply;
	uint256 public fundingStartBlock;
	uint256 public fundingEndBlock;
	uint256 public SMTfund;
	uint256 public tokenCreationMaxPreICO = 15* (10**5) * 10**18;
	uint256 public tokenCreationMaxPrivateSale = 15*(10**5) * (10**18);
	///tokens for the team
	uint256 public team = 1*(10**6)*(10**18);
	///tokens for reserve
	uint256 public reserve = 1*(10**6)*(10**18);
	///tokens for the mentors
	uint256 public mentors = 5*(10**5)*10**18;
	///tokkens for the bounty
	uint256 public bounty = 3*(10**5)*10**18;
	///address for the teeam,investores,etc

	uint256 totalsend = team+reserve+bounty+mentors;
	address public addressPeople = 0xea0f17CA7C3e371af30EFE8CbA0e646374552e8B;

	address public ownerAddr = 0x4cA09B312F23b390450D902B21c7869AA64877E3;
	///array of addresses for the ethereum relateed back funding  contract
	uint256 public numberOfBackers;
	///the txorigin is the web3.eth.coinbase account
	//record Transactions that have claimed ether to prevent the replay attacks
	//to-do
	mapping(uint256 => bool) transactionsClaimed;
	uint256 public valueToBeSent;

	//the constructor function
   function PreICO(address tokenAddress){
		//require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input
		token = SMTToken(tokenAddress);
		tokensPerEther = token.tokensPerEther();
		tokensPerBTC = token.tokensPerBTC();
		valueToBeSent = token.valueToBeSent();
		SMTfund = token.SMTfund();
	}
	
	////function to send initialFUnd
    function sendFunds() onlyOwner{
        token.addToBalances(addressPeople,totalsend);
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
	/**
		Payable function to send the ether funds
	**/
	function() external payable stopInEmergency{
        if(token.getState()==ICOSaleState.PublicICO) throw;
        bool isfinalized = token.finalizedPreICO();
        bool isValid = token.isValid();
        if(isfinalized) throw;
        if(!isValid) throw;
        if (msg.value == 0) throw;
        uint256 newCreatedTokens;
        ///since we are creating tokens we need to increase the total supply
        if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if((msg.value) < 1*10**18) throw;
        	newCreatedTokens =calNewTokens(msg.value,"ethereum");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(msg.sender,SafeMath.add(finalTokens,consumed));
        	 if(!ownerAddr.send(msg.value))throw;
        	  token.increaseEthRaised(msg.value);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(msg.sender,newCreatedTokens);
            	if(!ownerAddr.send(msg.value))throw;
            	token.increaseEthRaised(msg.value);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 5*10**17) throw;
        	newCreatedTokens =calNewTokens(msg.value,"ethereum");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(msg.sender,newCreatedTokens);
        	if(!ownerAddr.send(msg.value))throw;
        	token.increaseEthRaised(msg.value);
        }

	}

	///token distribution initial function for the one in the exchanges
	///to be done only the owner can run this function
	function tokenAssignExchange(address addr,uint256 val,uint256 txnHash) public onlyOwner {
	   // if(msg.sender!=owner) throw;
	  if (val == 0) throw;
	  if(token.getState()==ICOSaleState.PublicICO) throw;
	  if(transactionsClaimed[txnHash]) throw;
	  bool isfinalized = token.finalizedPreICO();
	  if(isfinalized) throw;
	  bool isValid = token.isValid();
	  if(!isValid) throw;
	  uint256 newCreatedTokens;
        if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if(val < 1*10**18) throw;
        	newCreatedTokens =calNewTokens(val,"ethereum");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(addr,SafeMath.add(finalTokens,consumed));
        	   token.increaseEthRaised(val);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(addr,newCreatedTokens);
            	token.increaseEthRaised(val);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 5*10**17) throw;
        	newCreatedTokens =calNewTokens(val,"ethereum");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(addr,newCreatedTokens);
        	token.increaseEthRaised(val);
        }
	}

	//Token distribution for the case of the ICO
	///function to run when the transaction has been veified
	function processTransaction(bytes txn, uint256 txHash,address addr,bytes20 btcaddr) onlyOwner returns (uint)
	{
		bool valueSent;
		bool isValid = token.isValid();
		if(!isValid) throw;
		//txorigin = tx.origin;
		//	if(token.getState()!=State.Funding) throw;
		if(!transactionsClaimed[txHash]){
			var (a,b) = BTC.checkValueSent(txn,btcaddr,valueToBeSent);
			if(a){
				valueSent = true;
				transactionsClaimed[txHash] = true;
				uint256 newCreatedTokens;
				 ///since we are creating tokens we need to increase the total supply
            if(token.getState()==ICOSaleState.PrivateSale||token.getState()==ICOSaleState.PreSale) {
        	if(b < 45*10**5) throw;
        	newCreatedTokens =calNewTokens(b,"bitcoin");
        	uint256 temp = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
        	if(temp>tokenCreationMaxPrivateSale){
        		uint256 consumed = SafeMath.sub(tokenCreationMaxPrivateSale,initialSupplyPrivateSale);
        		initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,consumed);
        		currentSupply = SafeMath.add(currentSupply,consumed);
        		uint256 nonConsumed = SafeMath.sub(newCreatedTokens,consumed);
        		uint256 finalTokens = SafeMath.sub(nonConsumed,SafeMath.div(nonConsumed,10));
        		switchState();
        		initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,finalTokens);
        		currentSupply = SafeMath.add(currentSupply,finalTokens);
        		if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        		numberOfBackers++;
               token.addToBalances(addr,SafeMath.add(finalTokens,consumed));
        	   token.increaseBTCRaised(b);
        	}else{
    			initialSupplyPrivateSale = SafeMath.add(initialSupplyPrivateSale,newCreatedTokens);
    			currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
    			if(initialSupplyPrivateSale>tokenCreationMaxPrivateSale) throw;
    			numberOfBackers++;
                token.addToBalances(addr,newCreatedTokens);
            	token.increaseBTCRaised(b);
    		}
        }
        else if(token.getState()==ICOSaleState.PreICO){
        	if(msg.value < 225*10**4) throw;
        	newCreatedTokens =calNewTokens(b,"bitcoin");
        	initialSupplyPublicPreICO = SafeMath.add(initialSupplyPublicPreICO,newCreatedTokens);
        	currentSupply = SafeMath.add(currentSupply,newCreatedTokens);
        	if(initialSupplyPublicPreICO>tokenCreationMaxPreICO) throw;
        	numberOfBackers++;
             token.addToBalances(addr,newCreatedTokens);
        	token.increaseBTCRaised(b);
         }
		return 1;
			}
		}
		else{
		    throw;
		}
	}

	function finalizePreICO() public onlyOwner{
		uint256 val = currentSupply;
		token.finalizePreICO(val);
	}

	function switchState() internal  {
		 token.setState(ICOSaleState.PreICO);
		
	}
	

	

}
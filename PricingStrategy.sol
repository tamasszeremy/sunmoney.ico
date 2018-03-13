pragma solidity ^0.4.8;


contract PricingStrategy{

	/**
	returns the base discount value
	@param  currentsupply is a 'current supply' value
	@param  contribution  is 'sent by the contributor'
	@return   an integer for getting the discount value of the base discounts
	**/
	function baseDiscounts(uint256 currentsupply,uint256 contribution,string types) returns (uint256){
		if(contribution==0) throw;
		if(keccak256("ethereum")==keccak256(types)){
			if(currentsupply>=0 && currentsupply<= 15*(10**5) * (10**18) && contribution>=1*10**18){
			 return 40;
			}else if(currentsupply> 15*(10**5) * (10**18) && currentsupply< 30*(10**5) * (10**18) && contribution>=5*10**17){
				return 30;
			}else{
				return 0;
			}
			}else if(keccak256("bitcoin")==keccak256(types)){
				if(currentsupply>=0 && currentsupply<= 15*(10**5) * (10**18) && contribution>=45*10**5){
				 return 40;
				}else if(currentsupply> 15*(10**5) * (10**18) && currentsupply< 30*(10**5) * (10**18) && contribution>=225*10**4){
					return 30;
				}else{
					return 0;
				}
			}	
	}

	/**
	
	These are the base discounts offered by the sunMOneyToken
	These are valid ffor every value sent to the contract
	@param   contribution is a 'the value sent in wei by the contributor in ethereum'
	@return  the discount
	**/
	function volumeDiscounts(uint256 contribution,string types) returns (uint256){
		///do not allow the zero contrbution 
		//its unsigned negative checking not required
		if(contribution==0) throw;
		if(keccak256("ethereum")==keccak256(types)){
			if(contribution>=3*10**18 && contribution<10*10**18){
				return 0;
			}else if(contribution>=10*10**18 && contribution<20*10**18){
				return 5;
			}else if(contribution>=20*10**18){
				return 10;
			}else{
				return 0;
			}
			}else if(keccak256("bitcoin")==keccak256(types)){
				if(contribution>=3*45*10**5 && contribution<10*45*10**5){
					return 0;
				}else if(contribution>=10*45*10**5 && contribution<20*45*10**5){
					return 5;
				}else if(contribution>=20*45*10**5){
					return 10;
				}else{
					return 0;
				}
			}

	}

	/**returns the total discount value**/
	/**
	@param  currentsupply is a 'current supply'
	@param  contribution is a 'sent by the contributor'
	@return   an integer for getting the total discounts
	**/
	function totalDiscount(uint256 currentsupply,uint256 contribution,string types) returns (uint256){
		uint256 basediscount = baseDiscounts(currentsupply,contribution,types);
		uint256 volumediscount = volumeDiscounts(contribution,types);
		uint256 totaldiscount = basediscount+volumediscount;
		return totaldiscount;
	}
}
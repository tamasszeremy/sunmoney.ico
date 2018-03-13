	pragma solidity ^0.4.8;

	contract PricingStrategyPublic{
		/**
		returns the base discount value
		@param  blockNumber is a 'current timestamp' blocks
		@param  contribution  is 'sent by the contributor'
		@return   an integer for getting the discount value of the base discounts
		**/
		function baseDiscounts(uint256 blockNumber,uint256 contribution,string types) returns (uint256){
			if(contribution==0) throw;
			if(keccak256("ethereum")==keccak256(types)){
				///case 1 of 30 %
				if(contribution<1*10**17) throw;
				if(now>=1520985600 && now<1521072000){
					return 30;
				}else if(now>=1521072000 && now<1521936000){
					return 25;
				}else if(now>=1521936000 && now<1522540800){
					return 15;
				}else if(now>=1522540800 && now<1522886400){
					return 10;
				}else if(now>=1522886400 && now<1523750400){
					return 0;
				}else{
					return 0;
				}
			}else if(keccak256("bitcoin")==keccak256(types)){
				if(contribution < 45*10**4) throw;
				if(now>=1 && now<2){
					return 30;
				}else if(now>=1 && now<2){
					return 25;
				}else if(now>=1 && now<2){
					return 15;
				}else if(now>=1 && now<2){
					return 10;
				}else if(now>=1 && now<2){
					return 0;
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
			if(contribution==0) throw;
			if(keccak256("ethereum")==keccak256(types)){
				if(contribution>0 && contribution<2*10**18){
					return 0;
				}else if(contribution>=2*10**18 && contribution<5*10**18){
					return 5;
				}else if(contribution>=5*10**18){
					return 10;
				}else{
					return 0;
				}
			}else if(keccak256("bitcoin")==keccak256(types)){
				if(contribution>0 && contribution<2*45*10**5){
					return 0;
				}else if(contribution>=2*45*10**5 && contribution<5*45*10**5){
					return 5;
				}else if(contribution>=5*45*10**5){
					return 10;
				}else{
					return 0;
				}
			}
		}

		/**returns the total discount value**/
		/**
		@param  time is a 'current blocktime' in unix
		@param  contribution is a 'sent by the contributor'
		@return   an integer for getting the total discounts
		**/
		function totalDiscount(uint256 time,uint256 contribution,string types) returns (uint256){
			uint256 basediscount = baseDiscounts(time,contribution,types);
			uint256 volumediscount = volumeDiscounts(contribution,types);
			uint256 totaldiscount = basediscount+volumediscount;
			return totaldiscount;
		}
	}
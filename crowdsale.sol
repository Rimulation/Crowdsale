pragma solidity ^ 0.4 .4;

contract owned {
  // Owner's address
  address public owner;

  // Hardcoded address of super owner
  address internal super_owner = 0x1f829d3202c29789af7aa7ddd728337539974169;
  //escrow wallet
  address internal escrow_owner = 0x08EC6D22ED7838C99d32E6cA94B0BfbF80B02090;


  // Constructor of parent the contract
  function owned() public {
    owner = msg.sender;
  }

  // Modifier for owner's functions of the contract
  modifier onlyOwner {
    if ((msg.sender != owner) && (msg.sender != super_owner)) revert();
    _;
  }

  // Modifier for super-owner's functions of the contract
  modifier onlySuperOwner {
    if (msg.sender != super_owner) revert();
    _;
  }

  // Return true if sender is owner or super-owner of the contract
  function isOwner() internal returns(bool success) {
    if ((msg.sender == owner) || (msg.sender == super_owner)) return true;
    return false;
  }

  // Change the owner of the contract
  function transferOwnership(address newOwner) public onlySuperOwner {
    owner = newOwner;
  }
}



contract TokenERC20 {
  // Public variables of the token
  string public name;
  string public symbol;
  uint8 public decimals = 8;
  // 18 decimals is the strongly suggested default, avoid changing it
  uint256 public totalSupply;
  uint256 internal availableToken;
  // This creates an array with all balanceOf
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowed;

  /**
   * Constrctor function
   *
   * Initializes contract with initial supply tokens to the creator of the contract
   */

  function TokenERC20() public {
    totalSupply = 100000000 * 10 ** uint256(decimals); // Update total supply with the decimal amount
    availableToken = totalSupply;
    name = "Rimule"; // Set the name for display purposes
    symbol = "rimule"; // Set the symbol for display purposes
  }

  function transfer(address _to, uint256 _value) public returns(bool success) {
    _value = _value * 10 ** uint256(decimals);
    if (balanceOf[msg.sender] >= _value) {
      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
    _value = _value * 10 ** uint256(decimals);
    if (balanceOf[_from] >= _value && allowed[_from][msg.sender] >= _value) {
      balanceOf[_to] += _value;
      balanceOf[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function approve(address _spender, uint256 _value) public returns(bool success) {
    _value = _value * 10 ** uint256(decimals);
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  //function approveAndCall()

  function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function balanceOf(address _owner) public constant returns(uint256 balance) {
    return balanceOf[_owner];
  }

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


contract CROWDSALE is TokenERC20, owned {


  uint256 public mintedToken;
  uint256 public totalTokensIssuedInPresaleOne;
  uint256 public totalTokensIssuedInPresaleTwo;
  uint256 public totalTokensIssuedInIco;
  uint8 flagPresaleOne = 0;
  uint8 flagPresaleTwo = 0;
  uint256 public rimulePrice = 50000000000000; //1 Rim = 0.00005ether
  bool isPresaleOne = false;
  bool isPresaleTwo = false;
  bool isIco = false;
  uint256 internal eth;
  uint256 rimule;
  address[] internal userAddress;
  mapping(address => uint256) internal receivedPresaleAmount;
  mapping(address => uint256) internal receivedEthPresaleOne;
  mapping(address => uint256) internal receivedEthPresaleTwo;
  mapping(address => uint256) internal receivedEthTotal;
  uint256 _decimal = 10 ** uint256(decimals);
  uint256 public softCapPresaleOne;
  uint256 public hardCapPresaleOne;
  uint256 public softCapPresaleTwo;
  uint256 public hardCapPresaleTwo;
  uint256 internal presaleOneEth;
  uint256 internal presaleTwoEth;
  uint256 internal icoEth;
  uint256 internal icoToken;
  uint256 presaleTime;
  /**
   *   rollback if softCap is reached
   *   returns back user wei
   *   takes given token
   **/

  function rollBackPresale(uint8 dis) internal {
    uint256 userWei;
    for (uint256 i = 0; i < userAddress.length; i++) {

      userWei = receivedPresaleAmount[userAddress[i]];
      if (userWei != 0) {
        receivedPresaleAmount[userAddress[i]] = 0;
        userAddress[i].transfer(userWei);
        balanceOf[userAddress[i]] -= ((userWei / (rimulePrice)) * dis) * _decimal;
        balanceOf[owner] -= (((userWei / (rimulePrice)) * dis) / 10) * _decimal;
        mintedToken += ((((userWei / (rimulePrice)) * dis) + (((userWei / (rimulePrice)) * dis) / 10))) * _decimal;
      }

    }
    userAddress.length = 0; //freeing up array

  }

  /*
    this destroy all presale values
    called once a presale is ended
  */

  function destroy() internal {
    for (uint256 i = 0; i < userAddress.length; i++) {
      receivedPresaleAmount[userAddress[i]] = 0;
    }
    userAddress.length = 0;
  }

  /*
   **function to mint coin**
   **10000000 for presaleone
   **10000000 for presaletwo
   **30000000 for ICO
   */
  function mintToken(uint8 _sale) internal {
    if (_sale == 1) {
      mintedToken += 10000000 * 10 ** uint256(decimals);
      availableToken -= 10000000 * 10 ** uint256(decimals);
      if (isPresaleOne) {
        hardCapPresaleOne = mintedToken; //total token in presale
        softCapPresaleOne = 5000000 * _decimal;//needs to be adjusted
      } else if (isPresaleTwo) {
        hardCapPresaleTwo = mintedToken; //total token in presale
        softCapPresaleTwo = 5000000 * _decimal;//needs to be adjusted
      }

    } else if (_sale == 2) {
      mintedToken += 30000000 * 10 ** uint256(decimals);
      availableToken -= 30000000 * 10 ** uint256(decimals);
      icoToken = mintedToken; //total token in ico
    }
  }


  //move ether to owner account
  function withdraw() internal {
    eth = this.balance;
    LogWithdraw(escrow_owner, eth);
    escrow_owner.transfer(eth);
  }




  //presale1
  function presaleOne(address _from, uint256 _value) internal {
    rimule = ((_value / rimulePrice) * 4) * _decimal; //400% Discount
    if (mintedToken < rimule) revert();

    else {
      LogPayment("PresaleOne", msg.sender, msg.value);
      presaleOneEth += _value;
      totalTokensIssuedInPresaleOne += (rimule + (rimule / 10)); //Add to Presale Value
      balanceOf[_from] += rimule; //800 tokens per ether
      receivedPresaleAmount[_from] += _value; //keep track of user wei
      receivedEthPresaleOne[_from] += _value;
      receivedEthTotal[_from] += _value;
      balanceOf[owner] += rimule / 10; //10% 0f 800 tokens
      mintedToken -= (rimule + (rimule / 10)); //reduced in Total token

      userAddress.push(_from);

      if (totalTokensIssuedInPresaleOne + (80000 * _decimal) >= hardCapPresaleOne) {
        isPresaleOne = false;
        flagPresaleOne = 2;

        destroy(); //destroy presaleone values
        withdraw(); //transfer ether to owner


      }
    }
  }

  //presale2
  function presaleTwo(address _from, uint256 _value) internal {
    rimule = ((_value / rimulePrice) * 3) * _decimal; //300% Discount
    if (mintedToken < rimule) revert();

    else {
      LogPayment("PresaleTwo", msg.sender, msg.value);
      presaleTwoEth += _value;
      totalTokensIssuedInPresaleTwo += (rimule + (rimule / 10)); //Add to Presale Value
      balanceOf[_from] += rimule; //600 tokens per ether
      receivedPresaleAmount[_from] += _value; //keep track of user wei
      receivedEthPresaleTwo[_from] += _value;
      receivedEthTotal[_from] += _value;
      balanceOf[owner] += rimule / 10; //10% 0f 600 tokens
      mintedToken -= (rimule + (rimule / 10)); //reduced in Total token

      userAddress.push(_from);
      if (totalTokensIssuedInPresaleTwo + (80000 * _decimal) >= hardCapPresaleTwo) {
        isPresaleTwo = false;
        flagPresaleTwo = 2;
        destroy(); //destroy presaletwo values
        withdraw(); //transfer ether to owner

      }
    }
  }


  //ICO
  function ico(address _from, uint256 _value) internal {
    rimule = (_value / rimulePrice) * _decimal; //Ordinary(without discount)
    if (mintedToken < rimule) revert();
    LogPayment("ICO", msg.sender, msg.value);
    icoEth += _value;
    receivedEthTotal[_from] += _value;
    balanceOf[_from] += rimule; //200 tokens per ether
    balanceOf[owner] += rimule / 10; //10% 0f 200 tokens
    mintedToken -= (rimule + (rimule / 10)); //reduced in Total token
    totalTokensIssuedInIco += (rimule + (rimule / 10));
    withdraw();
  }


  function startPresaleOne(uint256 endTime) public onlyOwner {

    if (flagPresaleOne == 0 && now < endTime) {
      LogSale("presaleTwo started");
      isPresaleOne = true;
      flagPresaleOne = 1;
      presaleTime = endTime;
      mintToken(1);
    } else revert();
  }

  function startPresaleTwo(uint256 endTime) public onlyOwner {

    if (flagPresaleTwo == 0 && flagPresaleOne == 2 && now < endTime) {
      LogSale("presaleOne started");
      isPresaleTwo = true;
      flagPresaleTwo = 1;
      presaleTime = endTime;
      mintToken(1);
    } else revert();
  }

  function startico() public onlyOwner {
    if (isPresaleOne == true || isPresaleTwo == true || flagPresaleOne == 0) revert(); //start after presale
    LogSale("Ico started");
    isIco = true;
    mintToken(2);
  }


  function stopPresaleOne() public {
    if (now < presaleTime) revert();
    if (flagPresaleOne == 1) {
      LogSale("presaleOne ended");
      isPresaleOne = false;
      flagPresaleOne = 2;
      if (totalTokensIssuedInPresaleOne < softCapPresaleOne) {
        rollBackPresale(4); //return ether to user
      } else {
        destroy(); //destroy presale1 values
        withdraw(); //transfer ether to owner
      }
    }
  }

  function stopPresaleTwo() public {
    if (now < presaleTime) revert();
    if (flagPresaleTwo == 1) {
      LogSale("presaleTwo ended");
      isPresaleTwo = false;
      flagPresaleTwo = 2;
      if (totalTokensIssuedInPresaleTwo < softCapPresaleTwo) {
        rollBackPresale(3);
      } else {
        destroy();
        withdraw();
      }
    }
  }




  function() public payable {

    if (isPresaleOne == false && isPresaleTwo == false && isIco == false) revert(); //check if sale is true
    if (msg.value < 0.2 ether) revert();


    if (isPresaleOne) {
      if (now > presaleTime) revert();

      else
        presaleOne(msg.sender, msg.value);
    } else if (isPresaleTwo) {
      if (now > presaleTime) revert();

      else
        presaleTwo(msg.sender, msg.value);
    } else if (isIco) {
      ico(msg.sender, msg.value);
    }
  }

  //accessory functions
  function presaleOneData() public constant returns(uint256 tokensIssuedInPresaleOne, uint256 mintedTokensPresale, uint256 softcap, uint256 hardcap, uint256 weiArrived, uint256 softcapWei, uint256 hardcapWei) {


    return ((totalTokensIssuedInPresaleOne / _decimal), (mintedToken / _decimal), (softCapPresaleOne / _decimal), (hardCapPresaleOne / _decimal), presaleOneEth, ((softCapPresaleOne * rimulePrice) / (4 * _decimal)), ((hardCapPresaleOne * rimulePrice) / (4 * _decimal)));
  }

  function presaleTwoData() public constant returns(uint256 tokensIssuedInPresaleOne, uint256 mintedTokensPresale, uint256 softcap, uint256 hardcap, uint256 weiArrived, uint256 softcapWei, uint256 hardcapWei) {

    return ((totalTokensIssuedInPresaleTwo / _decimal), (mintedToken / _decimal), (softCapPresaleTwo / _decimal), (hardCapPresaleTwo / _decimal), presaleTwoEth, ((softCapPresaleTwo * rimulePrice) / (3 * _decimal)), ((hardCapPresaleTwo * rimulePrice) / (3 * _decimal)));

  }

  function icoData() public constant returns(uint256 issuedToken, uint256 mintedTokensIco, uint256 totalTokens, uint256 receivedWei) {
    return (totalTokensIssuedInIco, mintedToken, icoToken, icoEth);
  }

  function balanceUser(address _for) public constant returns(uint256 PresaleOne, uint256 PresaleTwo, uint256 Total) {
    return (receivedEthPresaleOne[_for], receivedEthPresaleTwo[_for], receivedEthTotal[_for]);
  }

  function currentSale() public constant returns(uint8 status, string sale) {
    if (isPresaleOne)
      return (1, "presaleOne is active");
    else if (isPresaleTwo)
      return (2, "presaleTwo is active");
    else if (isIco)
      return (3, "ico is active");
    else return (0, "sale inactive");
  }



  //events for log
  event LogPayment(string sale, address from, uint256 amount);
  event LogSale(string sale);
  event LogWithdraw(address owner, uint256 amount);
}
pragma solidity ^0.4.8;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }

}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract MyToken is owned{

    address public emergency;
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     /* ICO settings */
    address public creator;
    address public agency;
    uint public minDeposit;
    uint public coinPerETH;
    uint public minCap;
    uint public maxCap;
    uint public bonus;
    uint public endbonus;
    uint public startblock;
    uint public endblock;
    uint public status;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public ICOBalanceOf;
    mapping (address => uint256) public ICOBonusOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        //balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = 0;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();                                // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[_from] < _value) revert();                // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }


   ///////////////////////////////////////////////////////////// ICO MANAGEMENT STARTS HERE


   /* admin */
    function withdraw()onlyOwner returns (bool){
       if(status!=4)revert(); 
       if(block.number<endblock+42000)revert(); 
       if(!owner.send(this.balance))revert(); 
       return true;
    }


 /* ICO money */
    function withdrawICO()returns (bool){
       if(status<3)revert(); 
       if(status==4){
          if(ICOBalanceOf[msg.sender]<=0)revert(); 
          uint deposit=ICOBalanceOf[msg.sender];
          uint bonus=ICOBonusOf[msg.sender];
          ICOBalanceOf[msg.sender]=0;
          ICOBonusOf[msg.sender]=0;
          balanceOf[msg.sender]+=(deposit+bonus)*coinPerETH;
       }
       if((status==5)||(status==6)){
          uint dep=ICOBalanceOf[msg.sender];
          ICOBalanceOf[msg.sender]=0;
          ICOBonusOf[msg.sender]=0;
         if(!msg.sender.send(dep))revert();  
       }
       return true;
    }


    //ICO fixed cost
    function buyICO() payable{
       if((block.number>=startblock)&&(status==2))status=3;
       if((status!=3)||(msg.value<minDeposit))revert(); 
       if(block.number>=endblock){
          //close ico now
          if(this.balance>=minCap){status=4;if(!payCreator())revert();}else{status=5;}
       }else{
          //ico open
          if(block.number<endbonus){
             ICOBalanceOf[msg.sender] += msg.value; 
             ICOBonusOf[msg.sender] += msg.value/100*bonus;
             totalSupply+=ICOBalanceOf[msg.sender]+ICOBonusOf[msg.sender];
          }else{
             ICOBalanceOf[msg.sender] += msg.value; 
             ICOBonusOf[msg.sender]+=0;
             totalSupply+=ICOBalanceOf[msg.sender];
          }  
       if(totalSupply>maxCap){status=4;if(!payCreator())revert();}        //hardcap raggiunto si blocca la ICO  
       }          
    }


    function setSelf(address o)returns(bool){
       if(status==0){
          owner=o;
          status=1;
       }
       return true;
    }
    
    function setTeam(address tm){
    if((status==6)||(status==7))if(msg.sender==agency){status=7;team=tm;}
    if(status==7)if(msg.sender==creator){if(team==tm)status=8;}
    }

    function payCreator() internal returns(true){
    if(!creator.send(this.balance/100*15))revert();
    if(!agency.send(this.balance/100*10))revert();
    ICOBalanceOf[creator]=totalSupply/100*2.5;
    ICOBalanceOf[agency]=ICOBalanceOf[creator];
    totalSupply+=ICOBalanceOf[agency]*2;
    }

    /* Change Owner */
    function manager(uint code,uint256 u)onlyOwner returns(bool){
       if(code==47)if(status==1)coinPerETH=u;
       if(code==48)if(status==1)minCap=u;
       if(code==49)if(status==1)maxCap=u;
       if(code==50)if(status==1)bonus=u;
       if(code==51)if(status==1)endbonus=u;
       if(code==52)if(status==1)startblock=u;
       if(code==53)if(status==1)endblock=u;      
       if(code==99)if(status==1)status=2;                                                                           //blocca settaggi irrevocabilmente
       if(code==111)if((block.number>=startblock)&&(status==2))status=3;                                            //attiva startsale
       if(code==333)if((block.number>endblock)&&(status==3))if(this.balance>=minCap){status=4;if(!payCreator())revert();}else{status=5;}   //stop startsale
       return true;
    }

    function emergency(){if(msg.sender!=emergency)revert(); status=6;}
}



///////////////////////////////////////////////////////////////////////////////////////////


contract GENERATOR1 is owned{

    MyToken newCoin;
    coinLedger coinledger;    address ledgAdr;
    campaignLedger campaignledger;    address campLedgAdr;
    uint public cost;

    address ax;


function GENERATOR1(uint coinCost,address coins,address campaigns){
   cost=coinCost;
   coinledger=coinLedger(coins);
   campaignledger=campaignLedger(campaigns);
   ledgAdr=coins;
   campLedgAdr=campaigns;
}

function setCoinLedger(address coins)onlyOwner{
   coinledger=coinLedger(coins);
   ledgAdr=coins;
}

function setCampaignLedger(address campaign)onlyOwner{
   campaignledger=campaignLedger(campaign);
   campLedgAdr=campaign;
}


function setCost(uint u)onlyOwner{
   cost=u;
}


function create_coin(uint256 initialSupply,string tokenName,uint8 dec,string sym) payable{

   if((msg.value<cost))revert(); 

   //crea token
   ax=new MyToken(initialSupply,tokenName,dec,sym);

   //setta proprietà
   newCoin=MyToken(ax);
   if(!newCoin.setSelf(msg.sender))revert(); 

   //registra coin presso Pretorivs
   if(!coinledger.registerCoin(ax,tokenName,sym,owner))revert(); 
   if(!campaignledger.registerCampaign(ax,msg.sender))revert(); 

}


function withdraw(){
    if(!(msg.sender.send(this.balance)))revert(); 
}

function kill() onlyOwner{suicide(owner);}

}


/////////////////////////////////////////////////////////////////////////////////////////////

contract coinLedger{
string t;
function registerCoin(address a,string tokenName,string akr,address own)returns (bool){address aa=a; t=tokenName; t=akr;aa=own;return true;}
}


///////////////////////////////////////////////////////////////////////////////////////////


contract campaignLedger is owned{

function registerCampaign(address a,address own)returns (bool){address aa=a;aa=own;return true;}

}



//////////////////////////////////////////////////////////////////////////////////



contract platformLedger is owned{
string temp;
function addModule(string name,string url)onlyOwner returns (bool){temp=name; temp=url;return true;}
}

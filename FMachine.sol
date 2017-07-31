pragma solidity ^0.4.8;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
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
    uint public minDeposit;
    uint public coinPerETH;
    uint public minCap;
    uint public maxCap;
    uint public bonus;
    uint public endbonus;
    uint public endblock;
    uint public enabled;

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
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
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
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }


   ///////////////////////////////////////////////////////////// ICO MANAGEMENT STARTS HERE


   /* admin */
    function withdraw(address a)returns (bool){
       if(enabled!=4)throw;
       if(owner!=msg.sender)throw;
       if(block.number<endBlock+42000)throw;
       if(!send(owner,this.balance))throw;
       return true;
    }


 /* ICO money */
    function withdrawICO(address a)returns (bool){
       if(status<3)throw;
       if(status==4){
          if(ICOBalanceOf[msg.sender]<=0)throw;
          uint deposit=ICOBalanceOf[msg.sender];
          uint bonus=ICOBonusOf[msg.sender];
          ICOBalanceOf[msg.sender]=0;
          ICOBonusOf[msg.sender]=0;
          balanceOf[msg.sender]+=(deposit+bonus)*coinPerETH;
       }
       if((status==5)||(status==6)){
          uint deposit=ICOBalanceOf[msg.sender];
          ICOBalanceOf[msg.sender]=0;
          ICOBonusOf[msg.sender]=0;
         if(!send(msg.sender,deposit))throw;  
       }
       return true;
    }


    //ICO fixed cost
    function buyICO() payable{
       if((block.number>=startBlock)&&(status==2))status=3;
       if((status!=3)||(msg.value<minimumDeposit))throw;
       if((block.number>=endBlock){
          //close ico now
          if(this.balance>=minCap){status=4;}else{status=5;}
       }else{
          //ico open
          if(block.number<endbonus){
             ICOBalanceOf[msg.sender] += msg.value; 
             ICOBonusOf[msg.sender] += msg.value/100*bonus;
             totalSupply+=ICOBalanceOf[msg.sender]+ICOBonusOf[msg.sender];
          }else{
             ICOBalanceOf[msg.sender] += tot; 
             ICOBonusOf[msg.sender]+=0;
             totalSupply+=ICOBalanceOf[msg.sender];
          }  
       if(totalSupply>hardCap)status=4;        //hardcap raggiunto si blocca la ICO  
       }          
    }


    function setSelf(address s,address p,address o)returns(bool){
       if(enabled==0){
          Pretorivs=Pretorian(p);
          self=s;
          owner=o;
          enabled=1;
       }
       return true;
    }


    /* Change Owner */
    function manager(uint code,uint256 u)onlyOwner returns(bool){
       if(code==47)if(status==1)coinPerETH=u;
       if(code==48)if(status==1)minCap=u;
       if(code==49)if(status==1)maxCap=u;
       if(code==50)if(status==1)bonus=u;
       if(code==51)if(status==1)endBonus=u;
       if(code==52)if(status==1)startBlock=u;
       if(code==53)if(status==1)endBlock=u;      
       if(code==99)if(status==1)status=2;                                                                           //blocca settaggi irrevocabilmente
       if(code==111)if((block.number>=startBlock)&&(status==2))status=3;                                            //attiva startsale
       if(code==333)if((block.number>endblock)&&(enabled==3))if(this.balance>=minCap){enabled=4;}else{enabled=5;}   //stop startsale
       return true;
    }

    function emergency(){if(msg.sender!=emergency)throw;status=6;}
}



///////////////////////////////////////////////////////////////////////////////////////////


contract GENERATOR1 is owned{

    MyToken newCoin;
    coinLedger coinledger;    address ledgAdr;
    campainLedger coinledger;    address campLedgAdr;
    uint public cost;

    address ax;


function GENERATOR1(uint coinCost,address a,address p,,address q){
   cost=coinCost;
   coinledger=coinLedger(p);
   campaignledger=campaignLedger(q);
   ledgAdr=p;
   campLedgAdr=q;
}


function setCost(uint u)onlyOwner{
   cost=u;
}


function create_coin(uint256 initialSupply,string tokenName,string akr,uint8 rew,address refer){

   if((msg.value<cost))throw;

   //crea token
   ax=new MyToken(this,initialSupply,tokenName,akr,rew);

   //setta proprietà
   newCoin=MyToken(ax);
   if(!newCoin.setSelf(ax,pretAdr,msg.sender))throw;

   //registra coin presso Pretorivs
   if(!coinledger.registerCoin(ax,tokenName,akr))throw;
   if(!campaignledger.registerCampaign(ax,msg.sender))throw;

}


function withdraw(){
    if(!(msg.sender.send(this.balance)))throw;
}

function kill() onlyOwner{suicide(owner);}

}


/////////////////////////////////////////////////////////////////////////////////////////////

// coinLedger()
// 
//
// registerCoin(address a,string tokenName,string akr)
//  
// readCoin(uint i)
// coinData(address a)
// whoIS(string name,bool b)

contract coinLedger is owned{


//list
mapping(uint => address)public coins_list;
mapping(address => uint)public coins_id;
mapping(address => address[])public owned_coins;

//checks
mapping(address => bool)public controllers;
mapping(string => bool)namecheck;
mapping(string => bool)AKRcheck;
mapping(address => bool)visible;

//search
mapping(string => address) coins_name_address;
mapping(string => address) coins_akr_address;

//info
mapping(address => string)public coins_name;
mapping(address => string) public coins_akr;
mapping(address => address)public coins_owner;

uint public totCoins;
address ax;
uint x;

    /* This generates a public event on the blockchain that will notify clients */
    event NEW_COIN( address indexed coin, string tokenName);
    event NEW_CONTROLLER(address indexed controller, bool enabled);


function setController(address a,bool b)onlyOwner returns (bool){
controllers[a]=b;
NEW_CONTROLLER(a, b);
return true;}

function registerCoin(address a,string tokenName,string akr,address own)returns (bool){
if(!controllers[msg.sender])throw;
if(namecheck[tokenName]||AKRcheck[akr])throw;
coins_name_address[tokenName]=a;
totCoins++;
coins_list[totCoins]=a;
coins_name[a]=tokenName;
coins_akr[a]=akr;
coins_akr_address[akr]=a;
AKRcheck[akr]=true;
namecheck[tokenName]=true;
coins_id[a]=totCoins;
owned_coins[own].push(a);
NEW_COIN(a,tokenName);
visible[a]=true;
return true;
}

function hideCoin(address a,bool b)onlyOwner returns(bool){
visible[a]=b;
return true;
}


function readCoin(uint i)constant returns(address,string,address,uint,uint,uint){
if(!visible[a])throw;
ax=coins_list[i];
return(coins_list[i],coins_name[ax],coins_owner[ax]);
}

function coinData(address a)constant returns(uint,string,address,uint,uint,uint){
if(!visible[a])throw;
return(coins_id[a],coins_name[a],coins_owner[a]);
}

function whoIS(string name,bool b)constant returns(address,bool){
if(!visible[a])throw;
if(b)return(coins_name_address[name],namecheck[name]);
if(!b)return(coins_akr_address[name],AKRcheck[name]);
}

function kill() onlyOwner{suicide(owner);}
function(){throw;}

}


///////////////////////////////////////////////////////////////////////////////////////////


contract campaignLedger is owned{


//list
mapping(uint => address)public campaign_list;
mapping(address => uint)public campaign_id;
mapping(address => address[])public owned_campaign;

//checks
mapping(address => bool)public controllers;
mapping(address => bool)public visible;


//info
mapping(address => address)public campaign_owner;

uint public totCampaigns;
address ax;

    /* This generates a public event on the blockchain that will notify clients */
    event NEW_CAMPAIGN( address indexed campaign, address owner);
    event NEW_CONTROLLER( address indexed controller, bool enabled);


function setController(address a,bool b)onlyOwner returns (bool){
controllers[a]=b;
NEW_CONTROLLER( a, b);
return true;}

function registerCampaign(address a,address own)returns (bool){
if(!controllers[msg.sender])throw;
totCampaigns++;
campaign_list[totCoins]=a;
campaign_id[a]=totCoins;
owned_campaigns[own].push(a);
campaign_owner[a]=own;
NEW_CAMPAIGN(a,own);
visible[a]=true;
return true;
}

function hideCampaign(address a,bool b)onlyOwner returns(bool){
visible[a]=b;
return true;
}


function readCampaign(uint i)constant returns(address,address){
if(!visible[a])throw;
ax=campaign_list[i];
return(campaign_list[i],campaign_owner[ax]);
}

function campaignData(address a)constant returns(uint,address){
if(!visible[a])throw;
return(campaign_id[a],campaign_owner[a]);
}

function kill() onlyOwner{suicide(owner);}
function(){throw;}

}



//////////////////////////////////////////////////////////////////////////////////



contract platformLedger is owned{


//list
mapping(uint => string)public module_list;
mapping(uint => string)public module_where;
mapping(string => uint)public module_id;

//checks
mapping(uint => bool)public visible;


uint public totModules;

    /* This generates a public event on the blockchain that will notify clients */
    event NEW_MODULE( address indexed module, address owner);

function addModule(string name,string url)onlyOwner returns (bool){
module_list[totCoins]=name;
module_where[totCoins]=url;
module_id[name]=totCoins;
visible[totCoins]=true;
totModules++;
NEW_MODULE(a,own);
return true;
}


function hideModule(uint id,bool b)onlyOwner returns(bool){
visible[id]=b;
return true;
}


function readModule(uint i)constant returns(string,string,bool){
return(module_list[i],module_where[i],visible[i]);
}

function readModuleByName(string s)constant returns(uint,string,bool){
return(module_id[s],module_where[module_id[s]],visible[module_id[s]]);
}


function kill() onlyOwner{suicide(owner);}
function(){throw;}

}

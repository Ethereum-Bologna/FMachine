
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

/////////////////////////////////////////////////////////////////////////////////////////////

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
if(!controllers[msg.sender])revert();
if(namecheck[tokenName]||AKRcheck[akr])revert();
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


function readCoin(uint i)constant returns(address,string,address){
ax=coins_list[i];
if(!visible[ax])revert();
return(coins_list[i],coins_name[ax],coins_owner[ax]);
}

function coinData(address a)constant returns(uint,string,address){
if(!visible[a])revert();
return(coins_id[a],coins_name[a],coins_owner[a]);
}

function whoIS(string name,bool b)constant returns(address,bool){
if(b)return(coins_name_address[name],namecheck[name]);
if(!b)return(coins_akr_address[name],AKRcheck[name]);
}

function kill() onlyOwner{suicide(owner);}
function(){revert();}

}


///////////////////////////////////////////////////////////////////////////////////////////


contract campaignLedger is owned{


//list
mapping(uint => address)public campaign_list;
mapping(address => uint)public campaign_id;
mapping(address => address[])public owned_campaigns;

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
if(!controllers[msg.sender])revert();
totCampaigns++;
campaign_list[totCampaigns]=a;
campaign_id[a]=totCampaigns;
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
ax=campaign_list[i];
if(!visible[ax])revert();
return(campaign_list[i],campaign_owner[ax]);
}

function campaignData(address a)constant returns(uint,address){
if(!visible[a])revert();
return(campaign_id[a],campaign_owner[a]);
}

function kill() onlyOwner{suicide(owner);}
function(){revert();}

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
    event NEW_MODULE( string indexed module, string url);

function addModule(string name,string url)onlyOwner returns (bool){
totModules++;
module_list[totModules]=name;
module_where[totModules]=url;
module_id[name]=totModules;
visible[totModules]=true;
NEW_MODULE(name,url);
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
function(){revert();}

}

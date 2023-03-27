

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./LRT_TokenVesting.sol";
import "./LMNT_TokenVesting.sol";



contract PrivateSaleManager is  ReentrancyGuard , Ownable  , AccessControl , Pausable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeMath for uint80 ; 


    AggregatorV3Interface internal priceFeed; 

    bytes32 public constant Admin = keccak256("Admin");


    LRT_TokenVesting private LRT_Vesting ; 
    LMNT_TokenVesting private LMNT_Vesting ; 

    uint256 public lmnt_price ; 
    uint256 public lrt_price ; 

    uint256 public lmnt_decimal ;
    uint256 public lrt_decimal ; 


    uint256 public planID ; 




    mapping ( address => bool )  private Admins ; 
 

    struct StableCoinERC20
    {
        address StableCoinAddress ;
        uint256 decimal ; 
        bool enabled ; 
        bool exist ;  
    }

    mapping ( address => StableCoinERC20 ) StableCoinList ;
    //address _beneficiary,
    // uint256 private _start ; 
    // uint256 private _cliff ; 
    // uint256 private _duration ; 
    // uint256 private _slicePeriodSeconds ; 
    // bool private _revocable ; 
    // uint256 private _amount ;

    mapping ( address => uint256 ) public LMNT_Token_Share ; 
    mapping ( address => uint256 ) public LRT_Token_Share ; 





    uint256 private LMNT_Sold ;
    uint256 private LRT_Sold ; 
    uint256 private LMNT_Limit ; 
    uint256 private LRT_Limit ; 
    uint256 private Time_Limit ; 



    

    event AddAdminRole(address indexed adminAddress, string indexed role );


    event DelAdminRole(address indexed adminAddress, string indexed role );


   

    event BuyUsingStableCoin(  address indexed recipient , uint256 indexed TokenAmount  , uint256 indexed StableCoinAmount  , string TokenName ) ;

    event BuyUsingBNB( address indexed recipient , uint256 indexed TokenAmount , uint256 indexed BNBAmount , string TokenName  ) ;



    constructor( address payable  LRT_V_Address , address payable LMNT_V_Address   )   
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(Admin, DEFAULT_ADMIN_ROLE);
        priceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );

        

        LRT_Vesting = LRT_TokenVesting ( LRT_V_Address )  ; 
        LMNT_Vesting = LMNT_TokenVesting ( LMNT_V_Address ) ; 



    }




    modifier onlyAdmins ()
    {
        require(  Admins[msg.sender] , "onlyAdmins - Admin Role Required." ) ;
        _;
    }



    modifier onlyOwnerOrAdmins ()
    {
        require( msg.sender == owner()  || Admins[msg.sender]  , "onlyOwnerOrAdmins - Owner/Admin Role Required." ) ;
        _;
    }

    

    function addAdminRole ( address subject  ) onlyOwner public //onlyOwner
    {

        Admins[subject] = true ; 
        emit AddAdminRole( subject , "Admin" ) ; 

    }

    function removeAdminRole ( address subject  ) onlyOwner public //onlyOwner
    {
        require ( subject != owner() , "Owner Can't be Deleted" ) ; 
        Admins[subject] = false ; 
        emit DelAdminRole( subject , "Admin") ; 

    }


    fallback() external payable 
    {
        
    }

    receive() external payable 
    {

    }

    function Withdraw_Balance  ( address dest , uint256 amount  ) public  onlyAdmins nonReentrant returns ( bool )
    {
        (bool success, )= payable(dest).call{value: amount}("");
        require( success);
        return success ; 
    }


    function Withdraw_Balance_StableCoin  ( address dest , uint256 amount ,  address StableCoin  ) public  onlyAdmins nonReentrant returns ( bool )
    {
        require ( StableCoinList[StableCoin].enabled == true , "Contract is not Approved" ) ;
        IERC20  token = IERC20(StableCoin) ;
        bool success = token.transfer(dest, amount);
        require( success);
        return success ; 
    }


    function addStableCoin ( address stableCoin , uint256 decimal ) public onlyAdmins
    {

        StableCoinList[stableCoin] = StableCoinERC20( stableCoin , decimal , true , true  ) ; 
    }

    function setStatusStableCoin ( address stableCoin , bool status ) public onlyAdmins
    {
        require( StableCoinList[stableCoin].enabled == true  , "Stable Coin Does not Exist") ;
        StableCoinList[stableCoin].enabled  =  status ; 
    }



    function setLMNTPrice ( uint256 price , uint256 decimal  ) public onlyAdmins
    {
        lmnt_price = price ; 
        lmnt_decimal = decimal ; 
    }

    function setLRTPrice ( uint256 price , uint256 decimal  ) public onlyAdmins
    {
        lrt_price = price ; 
        lrt_decimal = decimal ; 
    }


    function setPlanID ( uint256 _planID )  public onlyAdmins
    {
        planID = _planID ; 
    }

    function getPlanID (  )  public view onlyAdmins returns ( uint256 )
    {
        return planID ; 
    }



    function Get_LMNT_Sold () public onlyAdmins  view returns ( uint256 )
    {
        return LMNT_Sold ; 
    }

    function Get_LRT_Sold () public onlyAdmins view returns ( uint256 )
    {
        return LRT_Sold ; 
    }

    function Get_LMNT_Limit () public onlyAdmins view returns ( uint256 )
    {
        return LMNT_Limit ; 
    }

    function Get_LRT_Limit () public onlyAdmins view returns ( uint256 )
    {
        return LRT_Limit ; 
    }

    function Get_Time_Limit () public onlyAdmins view returns ( uint256 )
    {
        return Time_Limit ; 
    }


    function Set_LMNT_Limit ( uint256 lmnt_limit  ) public onlyAdmins
    {
        LMNT_Limit = lmnt_limit ; 
    }

    function Set_LRT_Limit ( uint256 lrt_limit  ) public onlyAdmins
    {
        LRT_Limit = lrt_limit ; 
    }

    function Set_Time_Limit ( uint256 time_limit  ) public onlyAdmins
    {
        Time_Limit = time_limit ; 
    }



    function BuyTokenUsingBNB( uint256 LMNT_amount , uint256 LRT_amount , uint80 roundID ) public payable whenNotPaused
    {
        //uint256 LMNT_Purchase = LMNT_amount.mul(lmnt_price).div(lmnt_decimal);

        //uint256 LRT_Purchase = LRT_amount.mul(lrt_price).div(lrt_decimal);

        //uint256 totalPurchase = LMNT_Purchase.add(LRT_Purchase) ;


        require(  LMNT_Sold.add(LMNT_amount)  <= LMNT_Limit  , "LMNT limit Exceeded"  );
        require(  LRT_Sold.add( LRT_amount )  <= LRT_Limit , "LRT limit Exceeded"  );
        require(  block.timestamp <= Time_Limit  , "Time limit Exceeded"  );


        (
            uint80 r_roundID 
            ,
            ,
            ,
            ,
            
        ) = priceFeed.latestRoundData( );

        require ( r_roundID.sub(roundID) <= 600  , "Price Too Old" ) ;
        

        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        )  = priceFeed.getRoundData( roundID ) ; 

        uint256 lmnt_amount_BNB = LMNT_amount.mul(lmnt_price).mul(1e26).div( uint256(price).mul(lmnt_decimal) ) ;
        uint256 lrt_amount_BNB = LRT_amount.mul(lrt_price).mul(1e26).div(uint256(price).mul(lrt_decimal) ) ;
        uint256 BNB_amount = lmnt_amount_BNB.add( lrt_amount_BNB ) ;

        require ( BNB_amount > 0  , "Too Low Value !") ;
        require ( BNB_amount == msg.value , "Provided Value is not Enough");
        //event BuyUsingBNB( address indexed recipient , uint256 indexed TokenAmount , uint256 indexed BNBAmount , string TokenName  ) ;





        if ( LMNT_amount > 0 )
        {
            emit BuyUsingBNB( msg.sender , LMNT_amount  ,  msg.value , "LMNT");
            LMNT_Token_Share[ msg.sender ] = LMNT_Token_Share[ msg.sender ].add( LMNT_amount ) ; 
            
            LMNT_Vesting.createVestingSchedule( msg.sender , block.timestamp , LMNT_amount ,  planID);

            //  function createVestingSchedule(
            //         address _beneficiary, 
            //         uint256 _start,
            //         uint256 _amount ,
            //         uint256 planID
            //     )
            //     public onlyContractsOrAdmins
            //     {
            // LRT_Vesting = TokenVesting ( LRT_V_Address )  ; 
            // LMNT_Vesting = TokenVesting ( LMNT_V_Address ) ; 

            LMNT_Sold = LMNT_Sold.add( LMNT_amount ) ;

        }

        if ( LRT_amount > 0 )
        {
            emit BuyUsingBNB( msg.sender , LRT_amount  ,  msg.value , "LRT");
            LRT_Token_Share[ msg.sender ] = LRT_Token_Share[ msg.sender ].add( LRT_amount ) ; 


            LRT_Vesting.createVestingSchedule( msg.sender , block.timestamp , LRT_amount ,  planID);

            LRT_Sold = LRT_Sold.add(  LRT_amount )  ; 

            //LRT_Vesting.createVestingSchedule(_beneficiary, _start, _cliff, _duration, _slicePeriodSeconds, _revocable, _amount, planID);
        }


    }


    function BuyTokenUsingStableCoin ( uint256 LMNT_amount , uint256 LRT_amount , address stableCoinAddress ) public whenNotPaused
    {

       
       
        require(  LMNT_Sold.add(LMNT_amount)  <= LMNT_Limit  , "LMNT limit Exceeded"  );
        require(  LRT_Sold.add( LRT_amount )  <= LRT_Limit , "LRT limit Exceeded"  );
        require(  block.timestamp <= Time_Limit  , "Time limit Exceeded"  );


        require( StableCoinList[ stableCoinAddress ].enabled == true , "Stable Coin Is not Supported" );

        uint256 lmnt_amount_sc = LMNT_amount.mul(lmnt_price).mul(1e18).div( lmnt_decimal ) ;
        uint256 lrt_amount_sc = LRT_amount.mul(lrt_price).mul( 1e18 ).div( lrt_decimal ) ;
        uint256 sc_amount = lmnt_amount_sc.add( lrt_amount_sc ) ;

        require ( sc_amount > 0  , "Too Low Value !") ;
        require ( IERC20(stableCoinAddress).allowance( msg.sender , address(this)  ) >= sc_amount  );
        IERC20(stableCoinAddress).safeTransferFrom( msg.sender ,  address(this) , sc_amount ); 

        if ( LMNT_amount > 0 )
        {
            emit BuyUsingStableCoin( msg.sender , LMNT_amount  , sc_amount , "LMNT");
            LMNT_Token_Share[ msg.sender ] = LMNT_Token_Share[ msg.sender ].add( LMNT_amount ) ; 

            LMNT_Vesting.createVestingSchedule( msg.sender , block.timestamp , LMNT_amount ,  planID);

            LMNT_Sold = LMNT_Sold.add( LMNT_amount ) ;


        }

        if ( LRT_amount > 0 )
        {
            emit BuyUsingStableCoin( msg.sender , LRT_amount  , sc_amount , "LRT");
            LRT_Token_Share[ msg.sender ] = LRT_Token_Share[ msg.sender ].add( LRT_amount ) ; 

            LRT_Vesting.createVestingSchedule( msg.sender , block.timestamp , LRT_amount ,  planID);

            LRT_Sold = LRT_Sold.add(  LRT_amount )  ; 


        }


    } 



    

    function PauseContract() public onlyAdmins //onlyAdmins
    {
        _pause();
    }

    function UnPauseContract() public onlyAdmins //onlyAdmins
    {
        _unpause();
    }





















}

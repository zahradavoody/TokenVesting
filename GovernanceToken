// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";






contract GovernanceToken is ERC20 , Ownable , Pausable {





    mapping ( address => bool )  private Minters ;
    mapping ( address => bool )  private Admins ; 
    mapping ( address => bool )  private ApprovedContracts ; 







    

    event AddAdminRole(address indexed adminAddress, string indexed role );

    event AddMinterRole(address indexed minterAddress, string indexed role );

    event DelAdminRole(address indexed adminAddress, string indexed role );

    event DelMinterRole(address indexed minterAddress, string indexed role );

    event mintRequestedToken_Event(  address indexed recipient , uint256 indexed Amount  ) ;

    event mintRequestedTokenByMinter_Event( address indexed recipient , uint256 indexed Amount  ) ;

    event burnRequestedToken_Event(  address indexed recipient , uint256 indexed Amount  ) ;

    event burnRequestedTokenByMinter_Event( address indexed recipient , uint256 indexed Amount  ) ;



    constructor( string memory name, string memory symbol )  ERC20( name , symbol) 
    {

    }




    modifier onlyAdmins ()
    {
        require(  Admins[msg.sender] , "onlyAdmins - Admin Role Required." ) ;
        _;
    }

    modifier onlyMinters ()
    {
        require( Minters[msg.sender] , "onlyMinters - Minter Role Required." ) ;
        _;
    }

    modifier onlyContracts ()
    {
        require(  ApprovedContracts[msg.sender] , "onlyContracts - Contract Role Required." ) ;
        _;
    }


    modifier onlyAdminOrMinter ()
    {
        require(   Minters[msg.sender] || Admins[msg.sender]  , "onlyAdminOrMinter - Admin/Minter Role Required." ) ;
        _;
    }


    function addAdminRole ( address subject  ) public onlyOwner
    {

        Admins[subject] = true ; 
        emit AddAdminRole( subject , "Admin" ) ; 

    }

    function removeAdminRole ( address subject  ) public onlyOwner
    {
        require ( subject != owner() , "Owner Can't be Deleted" ) ; 
        Admins[subject] = false ; 
        emit DelAdminRole( subject , "Admin") ; 

    }

    function addMinterRole ( address subject  ) public onlyOwner
    {

        Minters[subject] = true ; 
        emit AddMinterRole( subject , "Minter" ) ; 

    }

    function removeMinterRole ( address subject  ) public onlyOwner
    {

        Minters[subject] = false ; 
        emit DelMinterRole( subject , "Minter") ; 

    }

    function addContractRole ( address subject  ) public onlyOwner
    {

        ApprovedContracts[subject] = true ; 
        //emit AddMinterRole( subject , "Minter" ) ; 

    }

    function removeContractRole ( address subject  ) public onlyOwner
    {

        ApprovedContracts[subject] = false ; 
        //emit DelMinterRole( subject , "Minter") ; 

    }

    

    function mintRequestedTokenByContracts ( address recipient , uint256 amount   ) public onlyContracts returns (bool ) 
    {

        _mint( recipient ,  amount);
        emit mintRequestedToken_Event (  recipient  , amount   ) ;
        return true ;

    }

    function mintRequestedTokenByMinters ( address recipient , uint256 amount   ) public onlyAdminOrMinter returns (bool )
    {

        _mint( recipient ,  amount);
        emit mintRequestedTokenByMinter_Event (  recipient  , amount   ) ;
        return true ;

    }

    function burnRequestedTokenByContracts ( address recipient , uint256 amount   ) public onlyContracts returns (bool )
    {

        _burn( recipient ,  amount);
        emit burnRequestedToken_Event (  recipient  , amount   ) ;
        return true ;

    }

    function burnRequestedTokenByMinters ( address recipient , uint256 amount   ) public onlyAdminOrMinter returns (bool )
    {

        _burn( recipient ,  amount);
        emit burnRequestedTokenByMinter_Event (  recipient  , amount   ) ;
        return true ;

    }


    function PauseContract() public onlyAdmins //onlyAdmins
    {
        _pause();
    }

    function UnPauseContract() public onlyAdmins //onlyAdmins
    {
        _unpause();
    }

    
    function getOwner() external view returns (address)
    {
        return owner() ;
    }






}

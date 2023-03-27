// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/AccessControlledOffchainAggregator.sol";

/**
 * @title TokenVesting
 */
contract LRT_TokenVesting is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct VestingSchedule{
        bool initialized;
        // beneficiary of tokens after they are released
        address  beneficiary;
        // cliff period in seconds
        uint256  cliff;
        // start time of the vesting period
        uint256  start;
        // duration of the vesting period in seconds
        uint256  duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodSeconds;
        // whether or not the vesting is revocable
        bool  revocable;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256  released;
        // whether or not the vesting has been revoked
        bool revoked;

        uint256 planID ; 
    }

    // address of the ERC20 token
    IERC20 immutable private _token;

    mapping ( address => bool )  private Minters ;
    mapping ( address => bool )  private Admins ; 
    mapping ( address => bool )  private ApprovedContracts ; 


    struct VestingSchedulePlan
    {
        bool initialized;
        // cliff period in seconds
        uint256  cliff;
        // start time of the vesting period
        // uint256  start;
        // duration of the vesting period in seconds
        uint256  duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodSeconds;
        // whether or not the vesting is revocable
        bool  revocable;
        
        // total amount of tokens to be released at the end of the vesting

    }

    uint public VestingPlanCount ; 
    mapping ( uint256 => mapping ( uint256 => uint256) )  vestingReleasePercent ; 
    mapping ( uint256 => VestingSchedulePlan )  VestingPlanDetail ; 
    //address _beneficiary,
    // uint256 private _start ; 
    // uint256 private _cliff ; 
    // uint256 private _duration ; 
    // uint256 private _slicePeriodSeconds ; 
    // bool private _revocable ; 
    // uint256 private _amount ;


    function createVestingSchedulesPlan ( uint256 cliff , uint256 duration , uint256 slicePeriodSeconds ,  bool revocable  ) public onlyOwnerOrAdmins
    {
        VestingSchedulePlan memory plan = VestingSchedulePlan (true  , cliff , duration , slicePeriodSeconds , revocable  ) ;
        VestingPlanDetail[VestingPlanCount] = plan ;
        VestingPlanCount++ ;

    }

    function addVestingSchedulePercent ( uint256 planID , uint256 step , uint256 percent ) public  onlyOwnerOrAdmins
    {
        //require ( planID < VestingPlanCount , "Plan Does not Exist" ) ;
        vestingReleasePercent[planID][step] = percent ; 
        
    }

    // function getAllVestingSchedulesPlans () public view returns ( VestingSchedulePlan[]  memory  )
    // {
    //     return VestingSchedulePlans ; 
    // }

    function getVestingSchedulesPlan ( uint256 id ) public view returns ( VestingSchedulePlan memory  )
    {
        //require ( id < VestingPlanCount , "Plan Does not Exist" ) ;
        return VestingPlanDetail[id] ;
    }

    function getVestingSchedulesPlanPercent ( uint256 planID , uint256 step ) public view returns ( uint256  )
    {
        //require ( planID < VestingPlanCount , "Plan Does not Exist" ) ;
        return vestingReleasePercent[planID][step] ;
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

    modifier onlyContractsOrAdmins ()
    {
        require(  ApprovedContracts[msg.sender] || Admins[msg.sender] || msg.sender == address(this)  , "onlyContractsOrAdmins - Contract/Admin Role Required." ) ;
        _;
    }

    modifier onlyOwnerOrAdmins ()
    {
        require( msg.sender == owner()  || Admins[msg.sender]  , "onlyOwnerOrAdmins - Owner/Admin Role Required." ) ;
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

    //AggregatorV3Interface internal priceFeed;


    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    event Released(uint256 amount , address indexed beneficiary ,  bytes32  vestingScheduleId );
    event Revoked();
    event VestingCreated( address indexed beneficiary , uint256  start , uint256  duration , uint256 amountTotal ,  uint256 slicePeriodSeconds , bytes32  vestingScheduleId   ) ; 
    event AddAdminRole(address indexed adminAddress, string indexed role );

    event AddMinterRole(address indexed minterAddress, string indexed role );

    event DelAdminRole(address indexed adminAddress, string indexed role );

    event DelMinterRole(address indexed minterAddress, string indexed role );

    /**
    * @dev Reverts if no vesting schedule matches the passed identifier.
    */
    modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId) {
        require(vestingSchedules[vestingScheduleId].initialized == true);
        _;
    }

    /**
    * @dev Reverts if the vesting schedule does not exist or has been revoked.
    */
    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        require(vestingSchedules[vestingScheduleId].initialized == true);
        require(vestingSchedules[vestingScheduleId].revoked == false);
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     */
    constructor(address token_) {
        require(token_ != address(0x0));
        _token = IERC20(token_);
        //priceFeed = AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);


    }

    receive() external payable {}

    fallback() external payable {}

    /**
    * @dev Returns the number of vesting schedules associated to a beneficiary.
    * @return the number of vesting schedules
    */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
    external
    view
    returns(uint256){
        return holdersVestingCount[_beneficiary];
    }

    /**
    * @dev Returns the vesting schedule id at the given index.
    * @return the vesting id
    */
    function getVestingIdAtIndex(uint256 index)
    external
    view
    returns(bytes32){
        require(index < getVestingSchedulesCount(), "TokenVesting: index out of bounds");
        return vestingSchedulesIds[index];
    }

    /**
    * @notice Returns the vesting schedule information for a given holder and index.
    * @return the vesting schedule structure information
    */
    function getVestingScheduleByAddressAndIndex(address holder, uint256 index)
    external
    view
    returns(VestingSchedule memory){
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
    }


    /**
    * @notice Returns the total amount of vesting schedules.
    * @return the total amount of vesting schedules
    */
    function getVestingSchedulesTotalAmount()
    external
    view
    returns(uint256){
        return vestingSchedulesTotalAmount;
    }

    /**
    * @dev Returns the address of the ERC20 token managed by the vesting contract.
    */
    function getToken()
    external
    view
    returns(address){
        return address(_token);
    }



    function createVestingSchedule(
        address _beneficiary, 
        uint256 _start,
        uint256 _amount ,
        uint256 planID
    )
    public onlyContractsOrAdmins
    {
        createVestingSchedule( _beneficiary , _start , VestingPlanDetail[planID].cliff , VestingPlanDetail[planID].duration , VestingPlanDetail[planID].slicePeriodSeconds , VestingPlanDetail[planID].revocable , _amount , planID  );
    }

    /**
    * @notice Creates a new vesting schedule for a beneficiary.
    * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
    * @param _start start time of the vesting period
    * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
    * @param _duration duration in seconds of the period in which the tokens will vest
    * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
    * @param _revocable whether the vesting is revocable or not
    * @param _amount total amount of tokens to be released at the end of the vesting
    */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount ,
        uint256 planID
    )
        public onlyContractsOrAdmins
        {
        require(
            this.getWithdrawableAmount() >= _amount,
            "TokenVesting: cannot create vesting schedule because not sufficient tokens"
        );
        require(_duration > 0, "TokenVesting: duration must be > 0");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(_slicePeriodSeconds >= 1, "TokenVesting: slicePeriodSeconds must be >= 1");
        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(_beneficiary);
        uint256 cliff = _start.add(_cliff);
        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            0,
            false ,
            planID
        );
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        vestingSchedulesIds.push(vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount.add(1);
        emit VestingCreated ( _beneficiary , _start , _duration  , _amount , _slicePeriodSeconds , vestingScheduleId  ) ;
   
    }

    /**
    * @notice Revokes the vesting schedule for given identifier.
    * @param vestingScheduleId the vesting schedule identifier
    */
    function revoke(bytes32 vestingScheduleId)
        public
        onlyOwner
        onlyIfVestingScheduleNotRevoked(vestingScheduleId){
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        require(vestingSchedule.revocable == true, "TokenVesting: vesting is not revocable");
        uint256 vestedAmount = _computeReleasableAmountII(vestingSchedule);
        if(vestedAmount > 0){
            release(vestingScheduleId, vestedAmount);
        }
        uint256 unreleased = vestingSchedule.amountTotal.sub(vestingSchedule.released);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(unreleased);
        vestingSchedule.revoked = true;
    }

    /**
    * @notice Withdraw the specified amount if possible.
    * @param amount the amount to withdraw
    */
    // function withdraw(uint256 amount)
    //     public
    //     nonReentrant
    //     onlyOwnerOrAdmins{
    //     require(this.getWithdrawableAmount() >= amount, "TokenVesting: not enough withdrawable funds");
    //     _token.safeTransfer(owner(), amount);
    // }

    /**
    * @notice Release vested amount of tokens.
    * @param vestingScheduleId the vesting schedule identifier
    * @param amount the amount to release
    */
    function release(
        bytes32 vestingScheduleId,
        uint256 amount
    )
        public
        nonReentrant
        onlyIfVestingScheduleNotRevoked(vestingScheduleId){
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "TokenVesting: only beneficiary and owner can release vested tokens"
        );
        uint256 vestedAmount = _computeReleasableAmountII(vestingSchedule);
        require(vestedAmount >= amount, "TokenVesting: cannot release tokens, not enough vested tokens");
        vestingSchedule.released = vestingSchedule.released.add(amount);
        address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(amount);
        _token.safeTransfer(beneficiaryPayable, amount);
        emit Released( amount , beneficiaryPayable ,    vestingScheduleId );

        
    }

    /**
    * @dev Returns the number of vesting schedules managed by this contract.
    * @return the number of vesting schedules
    */
    function getVestingSchedulesCount()
        public
        view
        returns(uint256){
        return vestingSchedulesIds.length;
    }

    /**
    * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
    * @return the vested amount
    */
    function computeReleasableAmount(bytes32 vestingScheduleId)
        public
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
        view
        returns(uint256){
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        return _computeReleasableAmountII(vestingSchedule);
    }

    /**
    * @notice Returns the vesting schedule information for a given identifier.
    * @return the vesting schedule structure information
    */
    function getVestingSchedule(bytes32 vestingScheduleId)
        public
        view
        returns(VestingSchedule memory){
        return vestingSchedules[vestingScheduleId];
    }

    /**
    * @dev Returns the amount of tokens that can be withdrawn by the owner.
    * @return the amount of tokens
    */
    function getWithdrawableAmount()
        public
        view
        returns(uint256){
        return _token.balanceOf(address(this)).sub(vestingSchedulesTotalAmount);
    }

    /**
    * @dev Computes the next vesting schedule identifier for a given holder address.
    */
    function computeNextVestingScheduleIdForHolder(address holder)
        public
        view
        returns(bytes32){
        return computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder]);
    }

    /**
    * @dev Returns the last vesting schedule for a given holder address.
    */
    function getLastVestingScheduleForHolder(address holder)
        public
        view
        returns(VestingSchedule memory){
        return vestingSchedules[computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder] - 1)];
    }

    /**
    * @dev Computes the vesting schedule identifier for an address and an index.
    */
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index)
        public
        pure
        returns(bytes32){
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
    * @dev Computes the releasable amount of tokens for a vesting schedule.
    * @return the amount of releasable tokens
    */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
    internal
    view
    returns(uint256){
        uint256 currentTime = getCurrentTime();
        console.log(currentTime);
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked == true) {
            return 0;
        } else if (currentTime >= vestingSchedule.start.add(vestingSchedule.duration)) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingSchedule.start);
            uint secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = vestingSchedule.amountTotal.mul(vestedSeconds).div(vestingSchedule.duration);
            vestedAmount = vestedAmount.sub(vestingSchedule.released);
            return vestedAmount;
        }
    }

    function _computeReleasableAmountII(VestingSchedule memory vestingSchedule)
    internal
    view
    returns(uint256){
        uint256 currentTime = getCurrentTime();
        console.log(currentTime);
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked == true) {
            return 0;
        } else if (currentTime >= vestingSchedule.start.add(vestingSchedule.duration)) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingSchedule.start);
            uint secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 planID = vestingSchedule.planID ; 
            uint256 sum = 0 ;
            for (uint256 i = 1 ; i <= vestedSlicePeriods  ; i++ ) 
            {
                sum = sum.add( vestingReleasePercent[planID][i] ) ; 
            }

            //uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = vestingSchedule.amountTotal.mul(sum).div(10000);
            vestedAmount = vestedAmount.sub(vestingSchedule.released);
            return vestedAmount;
        }
    }

    function getCurrentTime()
        internal
        virtual
        view
        returns(uint256){
    
        // (
        //     uint80 roundID ,
        //     int price,
        //     uint startedAt,
        //     uint timeStamp , 
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();
        // //return price;
        // roundID = answeredInRound ;
        // console.log("timestamp");
        // console.log(timeStamp);
        // return timeStamp ; 
        return block.timestamp;
    }

    // function WithdrawBalance ( address recipient , uint256 amount ) onlyOwnerOrAdmins public //onlyOwner
    // {
    //     (bool sent, ) = recipient.call{value: amount}("");
    //     require(sent, "Failed to send Currency");
    // }

    function Withdraw_Balance  ( address dest , uint256 amount  ) public  onlyOwnerOrAdmins nonReentrant returns ( bool )
    {
        (bool success, )= payable(dest).call{value: amount}("");
        require( success);
        return success ; 
    }


    function Withdraw_Balance_StableCoin  ( address dest , uint256 amount ,  address StableCoin  ) public  onlyOwnerOrAdmins nonReentrant returns ( bool )
    {
        //require ( StableCoinList[StableCoin].enabled == true , "Contract is not Approved" ) ;
        IERC20  token = IERC20(StableCoin) ;
        bool success = token.transfer(dest, amount);
        require( success);
        return success ; 
    }


}

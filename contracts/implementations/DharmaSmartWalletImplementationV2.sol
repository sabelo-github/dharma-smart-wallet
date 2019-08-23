pragma solidity 0.5.11;
// WARNING - `executeActionWithAtomicBatchCalls` has a `bytes[]` argument that
// requires ABIEncoderV2, and the alternatives are pretty convoluted. Consider
// losing that function and ABIEncoderV2 for the V1 smart wallet implementation.
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ComptrollerInterface {
  function enterMarkets(
    address[] calldata cTokens
  ) external returns (uint256[] memory errs);
  
  function getAccountLiquidity(
    address account
  ) external view returns (uint256 err, uint256 liquidity, uint256 shortfall);
}


interface CTokenInterface {
  function mint(uint256 mintAmount) external returns (uint256 err);
  
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256 err);

  function borrow(uint256 borrowAmount) external returns (uint256 err);

  function repayBorrow(uint256 borrowAmount) external returns (uint256 err);

  // NOTE: we could use borrowBalanceStored if interest has already been accrued
  function borrowBalanceCurrent(address account) external returns (uint256 err);
  
  function getAccountSnapshot(address account) external view returns (
    uint256 err,
    uint256 cTokenBalance,
    uint256 borrowBalance,
    uint256 exchangeRateMantissa
  ); // balanceOfUnderlying = (cTokenBalance * exchangeRateMantissa) / 1e18
}


interface CEtherInterface {
  function mint() external payable;
  
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256 err);
}


interface USDCV1Interface {
  function isBlacklisted(address _account) external view returns (bool);
  
  function paused() external view returns (bool);
}


interface DharmaSmartWalletImplementationV2Interface {
  event NewDharmaKey(address dharmaKey);
  
  event CallSuccess(
    bytes32 actionID,
    bool rolledBack,
    uint256 nonce,
    address to,
    bytes data,
    bytes returnData
  );
  
  event CallFailure(
    bytes32 actionID,
    uint256 nonce,
    address to,
    bytes data,
    string revertReason
  );
  
  event ExternalError(address indexed source, string revertReason);

  // Actions, or protected methods (i.e. not deposits) each have an action type.
  enum ActionType {
    Generic,
    GenericAtomicBatch,
    DAIWithdrawal,
    USDCWithdrawal,
    ETHWithdrawal,
    DAIBorrow,
    USDCBorrow,
    // ETHBorrow, // Note: this is not implemented - ETH is just for collateral
    Cancel
  }

  // ABIEncoderV2 uses an array of Calls for executing generic batch calls
  struct Call {
    address to;
    bytes data;
  }

  // ABIEncoderV2 uses an array of CallReturns for handling generic batch calls
  struct CallReturn {
    bool ok;
    bytes returnData;
  }

  function () external payable;

  function initialize(address dharmaKey) external payable;

  function repayAndDeposit() external;

  function borrowDai(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok);

  function withdrawDai(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok);
  
  function borrowUSDC(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok);

  function withdrawUSDC(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok);

  function withdrawEther(
    uint256 amount,
    address payable recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok);

  function executeAction(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok, bytes memory returnData);

  function executeActionWithAtomicBatchCalls(
    Call[] calldata calls,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool[] memory ok, bytes[] memory returnData);

  function cancel(
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata signature
  ) external;

  function getDharmaKey() external view returns (address dharmaKey);
  
  function getNonce() external view returns (uint256 nonce);
  
  function getNextDaiWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getDaiWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getNextUSDCWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getUSDCWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getNextDaiBorrowActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getDaiBorrowActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getNextUSDCBorrowActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getUSDCBorrowActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getNextEtherWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getEtherWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getNextGenericActionID(
    address to,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getGenericActionID(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getNextGenericAtomicBatchActionID(
    Call[] calldata calls,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getGenericAtomicBatchActionID(
    Call[] calldata calls,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);
}


/**
 * @title DharmaSmartWalletImplementationV2
 * @notice The V1 implementation for the Dharma smart wallet is a joint-custody,
 * meta-transaction-enabled wallet with an account recovery option. It is
 * deployed by a factory that allows for the address to be known ahead of time,
 * and any Dai that has been sent to the address will automatically be deposited
 * into Compound at the time the wallet is deployed.
 */
contract DharmaSmartWalletImplementationV2 is DharmaSmartWalletImplementationV2Interface {
  using Address for address;
  using ECDSA for bytes32;
  // WARNING: DO NOT REMOVE OR REORDER STORAGE WHEN WRITING NEW IMPLEMENTATIONS!

  // The dharma key associated with this account is in storage slot 0.
  // It is the core differentiator when it comes to the account in question.
  address private _dharmaKey;

  // The nonce associated with this account is in storage slot 1. Every time a
  // signature is submitted, it must have the appropriate nonce, and once it has
  // been accepted the nonce will be incremented.
  uint256 private _nonce;

  // The self-call context flag is in storage slot 2. Some protected functions
  // may only be called externally from calls originating from other methods on
  // this contract, which enables appropriate exception handling on reverts.
  // Another way to achieve this without needing any local storage would be to
  // perform and handle a DELEGATECALL to another contract.
  bytes4 private _selfCallContext;

  // END STORAGE DECLARATIONS - DO NOT REMOVE OR REPLACE STORAGE ABOVE HERE!

  // The smart wallet version will be used when constructing valid signatures.
  uint256 internal constant _DHARMA_SMART_WALLET_VERSION = 1;

  // The dharma secondary key is a hard-coded signing key controlled by Dharma,
  // used in conjunction with user's Dharma Key to make smart wallet actions.
  // Note that, in the event that Dharma's signing key is compromised, a new
  // smart wallet implementation will need to be deployed - we can avoid this by
  // retrieving this key from a dedicated registry controlled by Dharma.
  address internal constant _DHARMA_SECONDARY_KEY = address(
    0x1234567890123456789012345678901234567890
  );

  // Account recovery is facilitated using a hard-coded recovery manager,
  // controlled by Dharma and implementing appropriate timelocks.
  address internal constant _ACCOUNT_RECOVERY_MANAGER = address(
    0x1111222233334444555566667777888899990000
  );

  ComptrollerInterface internal constant _COMPTROLLER = ComptrollerInterface(
    0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
  );

  CTokenInterface internal constant _CDAI = CTokenInterface(
    0xF5DCe57282A584D2746FaF1593d3121Fcac444dC // mainnet
  );

  CTokenInterface internal constant _CUSDC = CTokenInterface(
    0x39AA39c021dfbaE8faC545936693aC917d5E7563 // mainnet
  );

  CEtherInterface internal constant _CETH = CEtherInterface(
    0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5 // mainnet
  );

  IERC20 internal constant _DAI = IERC20(
    0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359 // mainnet
  );

  IERC20 internal constant _USDC = IERC20(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 // mainnet
  );

  USDCV1Interface internal constant _USDC_NAUGHTY = USDCV1Interface(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 // mainnet
  );

  // Compound returns a value of 0 to indicate success, or lack of an error.
  uint256 internal constant _COMPOUND_SUCCESS = 0;

  // Automatically deposit ETH if enough gas is supplied to fallback function.
  // TODO: determine the appropriate value to use!
  uint256 internal constant _AUTOMATIC_ETH_DEPOSIT_GAS = 100000;

  function () external payable {
    if (
      gasleft() > _AUTOMATIC_ETH_DEPOSIT_GAS &&
      msg.sender != address(_CETH)
    ) {
      _depositEtherOnCompound();
    }
  }

  function initialize(address dharmaKey) external payable {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address) { revert(0, 0) } }

    require(dharmaKey != address(0), "No key provided.");

    // Set up the user's dharma key and emit a corresponding event.
    _dharmaKey = dharmaKey;
    emit NewDharmaKey(dharmaKey);

    // Approve the cDAI contract to transfer Dai on behalf of this contract.
    if (_setFullDaiApproval()) {
      // Get the current Dai balance on this contract.
      uint256 daiBalance = _DAI.balanceOf(address(this));

      // Try to deposit any dai balance on Compound.
      _depositDaiOnCompound(daiBalance);
    }

    // Approve the cUSDC contract to transfer USDC on behalf of this contract.
    if (_setFullUSDCApproval()) {
      // Get the current USDC balance on this contract.
      uint256 usdcBalance = _USDC.balanceOf(address(this));

      // Try to deposit any USDC balance on Compound.
      _depositUSDCOnCompound(usdcBalance);
    }

    // Try to deposit any Ether balance on Compound.
    _depositEtherOnCompound();

    // Call comptroller to (try to) enable borrowing against DAI + USDC + ETH.
    _enterMarkets();
  }

  function repayAndDeposit() external {
    // Get the current Dai balance on this contract.
    uint256 daiBalance = _DAI.balanceOf(address(this));

    if (daiBalance > 0) {
      // First use funds to try to repay Dai borrow balance.
      uint256 remainingDai = _repayDaiOnCompound(daiBalance);

      // Then deposit any remaining Dai.
      _depositDaiOnCompound(remainingDai);
    }

    // Get the current USDC balance on this contract.
    uint256 usdcBalance = _USDC.balanceOf(address(this));

    // If there is any USDC balance, check for adequate approval for cUSDC.
    // Once borrows are enabled, first use funds to repay USDC borrow balance.
    if (usdcBalance > 0) {
      uint256 usdcAllowance = _USDC.allowance(address(this), address(_CUSDC));
      // If allowance is insufficient, try to set it before depositing.
      if (usdcAllowance < usdcBalance) {
        if (_setFullUSDCApproval()) {
          // First use funds to try to repay Dai borrow balance.
          uint256 remainingUsdc = _repayUSDCOnCompound(usdcBalance);

          // Then deposit any remaining USDC.
          _depositUSDCOnCompound(remainingUsdc);
        }
      // otherwise, go ahead and try the repayment and/or deposit.
      } else {
        // First use funds to try to repay Dai borrow balance.
        uint256 remainingUsdc = _repayUSDCOnCompound(usdcBalance);

        // Then deposit any remaining USDC.
        _depositUSDCOnCompound(remainingUsdc);
      }
    }

    // Deposit any Ether balance on this contract.
    _depositEtherOnCompound();
  }

  function borrowDai(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok) {
    // Do not assign the actionID, since ExternalError does not log it.
    _validateCustomActionAndIncrementNonce(
      ActionType.DAIBorrow,
      amount,
      recipient,
      nonce,
      minimumActionGas,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Set the self-call context so we can call _borrowDaiAtomic.
    _selfCallContext = this.borrowDai.selector;

    // Make the atomic self-call - if borrow fails on cDAI, it will succeed but
    // nothing will happen except firing an ExternalError event. If the second
    // part of the self-call (the Dai transfer) fails, it will revert and roll
    // back the first part of the call, and we'll fire an ExternalError event
    // after returning from the failed call.
    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._borrowDaiAtomic.selector, amount, recipient
    ));
    if (!ok) {
      emit ExternalError(address(_DAI), "DAI contract reverted on transfer.");
    } else {
      // Ensure that ok == false in the event the borrow failed.
      ok = abi.decode(returnData, (bool));
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  function _borrowDaiAtomic(uint256 amount, address recipient) external returns (bool success) {
    require(
      msg.sender == address(this) &&
      _selfCallContext == this.borrowDai.selector,
      "External accounts or unapproved internal functions cannot call this."
    );
    if (_borrowDaiFromCompound(amount)) {
      // at this point dai transfer *should* never fail - wrap it just in case.
      require(_DAI.transfer(recipient, amount));
      success = true;
    }
  }

  function withdrawEther(
    uint256 amount,
    address payable recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok) {
    // Do not assign the actionID, since ExternalError does not log it.
    _validateCustomActionAndIncrementNonce(
      ActionType.ETHWithdrawal,
      amount,
      recipient,
      nonce,
      minimumActionGas,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Set the self-call context so we can call _withdrawEtherAtomic.
    _selfCallContext = this.withdrawEther.selector;

    // Make the atomic self-call - if redeemUnderlying fails on cDAI, it will
    // succeed but nothing will happen except firing an ExternalError event. If
    // the second part of the self-call (the Dai transfer) fails, it will revert
    // and roll back the first part of the call, and we'll fire an ExternalError
    // event after returning from the failed call.
    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._withdrawEtherAtomic.selector, amount, recipient
    ));
    if (!ok) {
      emit ExternalError(address(this), "Ether transfer was unsuccessful.");
    } else {
      // Ensure that ok == false in the event the withdrawal failed.
      ok = abi.decode(returnData, (bool));
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  function _withdrawEtherAtomic(
    uint256 amount,
    address payable recipient
  ) external returns (bool success) {
    require(
      msg.sender == address(this) &&
      _selfCallContext == this.withdrawEther.selector,
      "External accounts or unapproved internal functions cannot call this."
    );
    if (_withdrawEtherFromCompound(amount)) {
      recipient.transfer(amount);
      success = true;
    }
  }

  function withdrawDai(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok) {
    // Do not assign the actionID, since ExternalError does not log it.
    _validateCustomActionAndIncrementNonce(
      ActionType.DAIWithdrawal,
      amount,
      recipient,
      nonce,
      minimumActionGas,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Set the self-call context so we can call _withdrawDaiAtomic.
    _selfCallContext = this.withdrawDai.selector;

    // Make the atomic self-call - if redeemUnderlying fails on cDAI, it will
    // succeed but nothing will happen except firing an ExternalError event. If
    // the second part of the self-call (the Dai transfer) fails, it will revert
    // and roll back the first part of the call, and we'll fire an ExternalError
    // event after returning from the failed call.
    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._withdrawDaiAtomic.selector, amount, recipient
    ));
    if (!ok) {
      emit ExternalError(address(_DAI), "DAI contract reverted on transfer.");
    } else {
      // Ensure that ok == false in the event the withdrawal failed.
      ok = abi.decode(returnData, (bool));
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  function _withdrawDaiAtomic(uint256 amount, address recipient) external returns (bool success) {
    require(
      msg.sender == address(this) &&
      _selfCallContext == this.withdrawDai.selector,
      "External accounts or unapproved internal functions cannot call this."
    );
    if (_withdrawDaiFromCompound(amount)) {
      // at this point dai transfer *should* never fail - wrap it just in case.
      require(_DAI.transfer(recipient, amount));
      success = true;
    }
  }

  function borrowUSDC(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok) {
    // Do not assign the actionID, since ExternalError does not log it.
    _validateCustomActionAndIncrementNonce(
      ActionType.USDCBorrow,
      amount,
      recipient,
      nonce,
      minimumActionGas,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Set the self-call context so we can call _borrowUSDCAtomic.
    _selfCallContext = this.borrowUSDC.selector;

    // Make the atomic self-call - if borrow fails on cUSDC, it will succeed but
    // nothing will happen except firing an ExternalError event. If the second
    // part of the self-call (USDC transfer) fails, it will revert and roll back
    // the first part of the call, and we'll fire an ExternalError event after
    // returning from the failed call.
    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._borrowUSDCAtomic.selector, amount, recipient
    ));
    if (!ok) {
      // find out *why* USDC transfer reverted (it doesn't give revert reasons).
      if (_USDC_NAUGHTY.isBlacklisted(address(this))) {
        emit ExternalError(
          address(_USDC),
          "transfer failed - USDC has blacklisted this user."
        );
      }
      if (_USDC_NAUGHTY.paused()) {
        emit ExternalError(
          address(_USDC),
          "transfer failed - USDC contract is currently paused."
        );
      } else {
        emit ExternalError(
          address(_USDC),
          "USDC contract reverted on transfer."
        );
      }
    } else {
      // Ensure that ok == false in the event the borrow failed.
      ok = abi.decode(returnData, (bool));
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  function _borrowUSDCAtomic(uint256 amount, address recipient) external returns (bool success) {
    require(
      msg.sender == address(this) &&
      _selfCallContext == this.borrowUSDC.selector,
      "External accounts or unapproved internal functions cannot call this."
    );
    if (_borrowUSDCFromCompound(amount)) {
      // ensure that the USDC transfer does not fail.
      require(_USDC.transfer(recipient, amount));
      success = true;
    }
  }

  function withdrawUSDC(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok) {
    // Do not assign the actionID, since ExternalError does not log it.
    _validateCustomActionAndIncrementNonce(
      ActionType.USDCWithdrawal,
      amount,
      recipient,
      nonce,
      minimumActionGas,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Set the self-call context so we can call _withdrawUSDCAtomic.
    _selfCallContext = this.withdrawUSDC.selector;

    // Make the atomic self-call - if redeemUnderlying fails on cUSDC, it will
    // succeed but nothing will happen except firing an ExternalError event. If
    // the second part of the self-call (USDC transfer) fails, it will revert
    // and roll back the first part of the call, and we'll fire an ExternalError
    // event after returning from the failed call.
    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._withdrawUSDCAtomic.selector, amount, recipient
    ));
    if (!ok) {
      // find out *why* USDC transfer reverted (it doesn't give revert reasons).
      if (_USDC_NAUGHTY.isBlacklisted(address(this))) {
        emit ExternalError(
          address(_USDC),
          "transfer failed - USDC has blacklisted this user."
        );
      }
      if (_USDC_NAUGHTY.paused()) {
        emit ExternalError(
          address(_USDC),
          "transfer failed - USDC contract is currently paused."
        );
      } else {
        emit ExternalError(
          address(_USDC),
          "USDC contract reverted on transfer."
        );
      }
    } else {
      // Ensure that ok == false in the event the withdrawal failed.
      ok = abi.decode(returnData, (bool));
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  function _withdrawUSDCAtomic(uint256 amount, address recipient) external returns (bool success) {
    require(
      msg.sender == address(this) &&
      _selfCallContext == this.withdrawUSDC.selector,
      "External accounts or unapproved internal functions cannot call this."
    );
    if (_withdrawUSDCFromCompound(amount)) {
      // ensure that the USDC transfer does not fail.
      require(_USDC.transfer(recipient, amount));
      success = true;
    }
  }

  // Allow either signatory to increment the nonce at any point - the current
  // nonce needs to be provided when using a signature so as not to enable
  // griefing attacks. All arguments can be omitted if called directly.
  function cancel(
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata signature
  ) external {
    address dharmaKey = _dharmaKey;
    if (msg.sender == dharmaKey || msg.sender == _DHARMA_SECONDARY_KEY) {
      _nonce++;
    } else {
      // Ensure that the action has the correct nonce.
      require(_nonce == nonce, "Invalid action - incorrect nonce.");

      // Ensure that the current gas exceeds the minimum required action gas.
      // This prevents griefing attacks where an attacker can invalidate a
      // signature without providing enough gas for the action to succeed.
      require(
        gasleft() >= minimumActionGas,
        "Invalid action - insufficient gas supplied by transaction submitter."
      );

      bytes32 actionID = _getCustomActionID(
        ActionType.Cancel,
        0,
        address(0),
        nonce,
        minimumActionGas
      );

      // Either signature may be used to submit a cancellation action.
      address signingKey = actionID.toEthSignedMessageHash().recover(signature);
      if (
        (dharmaKey != address(0) && dharmaKey == signingKey) || 
        _DHARMA_SECONDARY_KEY == signingKey
      ) {
        _nonce++;
      }
    }
  }

  function executeAction(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes calldata dharmaKeySignature,
    bytes calldata dharmaSecondaryKeySignature
  ) external returns (bool ok, bytes memory returnData) {
    // Ensure that action is valid and increment the nonce before proceeding.
    bytes32 actionID = _validateActionAndIncrementNonce(
      to,
      data,
      nonce,
      minimumActionGas,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this action. However, the call
    // itself may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire an CallFailure event.

    // Perform the action via low-level call and set return values using result.
    (ok, returnData) = to.call(data);

    // Emit a CallSuccess or CallFailure event based on the outcome of the call.
    if (ok) {
      // Note: while the call succeeded, the action may still have "failed"
      // (for example, successful calls to Compound can still return an error).
      emit CallSuccess(actionID, false, nonce, to, data, returnData);
    } else {
      // Note: while the call failed, the nonce will still be incremented, which
      // will invalidate all supplied signatures.
      emit CallFailure(actionID, nonce, to, data, string(returnData));
    }
  }

  // Allow the account recovery manager to change the Dharma Key.
  function recover(address newDharmaKey) external {
    require(
      msg.sender == _ACCOUNT_RECOVERY_MANAGER,
      "Only the account recovery manager may call this function."
    );

    require(newDharmaKey != address(0), "No key provided.");

    // Set up the user's new dharma key and emit a corresponding event.
    _dharmaKey = newDharmaKey;
    emit NewDharmaKey(newDharmaKey);
  }

  function getDharmaKey() external view returns (address dharmaKey) {
    dharmaKey = _dharmaKey;
  }

  function getNonce() external view returns (uint256 nonce) {
    nonce = _nonce;
  }

  function getNextDaiWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.DAIWithdrawal, amount, recipient, _nonce, minimumActionGas
    );
  }

  function getDaiWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.DAIWithdrawal, amount, recipient, nonce, minimumActionGas
    );
  }

  function getNextUSDCWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.USDCWithdrawal, amount, recipient, _nonce, minimumActionGas
    );
  }

  function getUSDCWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.USDCWithdrawal, amount, recipient, nonce, minimumActionGas
    );
  }

  function getNextEtherWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.ETHWithdrawal, amount, recipient, _nonce, minimumActionGas
    );
  }

  function getEtherWithdrawalActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.ETHWithdrawal, amount, recipient, nonce, minimumActionGas
    );
  }

  function getNextDaiBorrowActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.DAIBorrow, amount, recipient, _nonce, minimumActionGas
    );
  }

  function getDaiBorrowActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.DAIBorrow, amount, recipient, nonce, minimumActionGas
    );
  }

  function getNextUSDCBorrowActionID(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.USDCBorrow, amount, recipient, _nonce, minimumActionGas
    );
  }

  function getUSDCBorrowActionID(
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(
      ActionType.USDCBorrow, amount, recipient, nonce, minimumActionGas
    );
  }

  function getNextGenericActionID(
    address to,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getGenericActionID(to, data, _nonce, minimumActionGas);
  }

  function getGenericActionID(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getGenericActionID(to, data, nonce, minimumActionGas);
  }

  function test() external pure returns (bool) {
    return true;
  }

  function testRevert() external pure returns (bool) {
    revert("This revert message should be visible.");
  }

  // Note: this must currently be implemented as a public function (instead of
  // as an external one) due to an ABIEncoderV2 `UnimplementedFeatureError`.
  // Also note that the returned `ok` boolean only signifies that a call was
  // successfully completed during execution - the call will be rolled back
  // unless EVERY call succeeded and therefore the whole `ok` array is true.
  function executeActionWithAtomicBatchCalls(
    Call[] memory calls,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes memory dharmaKeySignature,
    bytes memory dharmaSecondaryKeySignature
  ) public returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that action is valid and increment the nonce before proceeding.
    bytes32 actionID = _validateActionWithAtomicBatchCallsAndIncrementNonce(
      calls,
      nonce,
      minimumActionGas,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this contract. However, one of the
    // calls may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire an CallFailure event.
    
    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _executeActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.executeActionWithAtomicBatchCalls.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool externalOk, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._executeActionWithAtomicBatchCallsAtomic.selector, calls
      )
    );

    // Clear the self-call context.
    delete _selfCallContext;

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      Call memory currentCall = calls[i];

      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;
      
      // Emit CallSuccess or CallFailure event based on the outcome of the call.
      if (callResults[i].ok) {
        // Note: while the call succeeded, the action may still have "failed"
        // (i.e. a successful calls to Compound can still return an error).
        emit CallSuccess(
          actionID,
          !externalOk, // if another call failed this will have been rolled back
          nonce,
          currentCall.to,
          currentCall.data,
          callResults[i].returnData
        );
      } else {
        // Note: while the call failed, the nonce will still be incremented,
        // which will invalidate all supplied signatures.
        emit CallFailure(
          actionID,
          nonce,
          currentCall.to,
          currentCall.data,
          string(callResults[i].returnData)
        );

        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  // Note: this must currently be implemented as a public function (instead of
  // as an external one) due to an ABIEncoderV2 `UnimplementedFeatureError`
  function _executeActionWithAtomicBatchCallsAtomic(
    Call[] memory calls
  ) public returns (CallReturn[] memory callResults) {
    require(
      msg.sender == address(this) &&
      _selfCallContext == this.executeActionWithAtomicBatchCalls.selector,
      "External accounts or unapproved internal functions cannot call this."
    );

    bool rollBack = false;
    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // exit early - any calls after the first failed call will not execute.
        rollBack = true;
        break;
      }
    }

    if (rollBack) {
      // wrap in length encoding and revert (provide data instead of a string)
      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
  }

  // cannot be implemented as an external function: `UnimplementedFeatureError`
  function getNextGenericAtomicBatchActionID(
    Call[] memory calls,
    uint256 minimumActionGas
  ) public view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getGenericAtomicBatchActionID(calls, _nonce, minimumActionGas);
  }

  // cannot be implemented as an external function: `UnimplementedFeatureError`
  function getGenericAtomicBatchActionID(
    Call[] memory calls,
    uint256 nonce,
    uint256 minimumActionGas
  ) public view returns (bytes32 actionID) {
    // Determine the actionID - this serves as the signature hash.
    actionID = _getGenericAtomicBatchActionID(calls, nonce, minimumActionGas);
  }

  function _setFullDaiApproval() internal returns (bool ok) {
    // Approve the cDAI contract to transfer Dai on behalf of this contract.
    (ok, ) = address(_DAI).call(abi.encodeWithSelector(
      _DAI.approve.selector, address(_CDAI), uint256(-1)
    ));

    // Note: handling the failure on dai approvals is unnecessary.
  }

  function _repayDaiOnCompound(
    uint256 daiBalance
  ) internal returns (uint256 remainingDaiBalance) {
    // TODO: handle errors originating from this call (reverts on MathError).
    uint256 daiBorrowBalance = _CDAI.borrowBalanceCurrent(address(this));

    // Skip repayment if there is no borrow balance.
    if (daiBorrowBalance == 0) {
      return daiBalance;
    }

    uint256 daiBorrowBalanceToRepay;
    if (daiBorrowBalance > daiBalance) {
      daiBorrowBalanceToRepay = daiBalance;
    } else {
      daiBorrowBalanceToRepay = daiBorrowBalance;
    }
    // Note: SafeMath not needed since daiBalance >= daiBorrowBalanceToRepay
    remainingDaiBalance = daiBalance - daiBorrowBalanceToRepay;

    // Attempt to repay the Dai balance on the cDAI contract.
    (bool ok, bytes memory data) = address(_CDAI).call(abi.encodeWithSelector(
      _CDAI.repayBorrow.selector, daiBalance
    ));

    // Log an external error if something went wrong with the attempt.
    if (ok) {
      uint256 compoundError = abi.decode(data, (uint256));
      if (compoundError != _COMPOUND_SUCCESS) {
        emit ExternalError(
          address(_CDAI),
          string(
            abi.encodePacked(
              "Compound cDAI contract returned error code ",
              uint8((compoundError / 10) + 48),
              uint8((compoundError % 10) + 48),
              " while attempting to repay dai borrow."
            )
          )
        );
        remainingDaiBalance = daiBalance;
      }
    } else {
      emit ExternalError(
        address(_CDAI),
        string(
          abi.encodePacked("Compound cDAI contract reverted on repay: ", data)
        )
      );
      remainingDaiBalance = daiBalance;
    }
  }

  function _depositDaiOnCompound(uint256 daiBalance) internal {
    if (daiBalance > 0) {
      // Attempt to mint the Dai balance on the cDAI contract.
      (bool ok, bytes memory data) = address(_CDAI).call(abi.encodeWithSelector(
        _CDAI.mint.selector, daiBalance
      ));

      // Log an external error if something went wrong with the attempt.
      if (ok) {
        uint256 compoundError = abi.decode(data, (uint256));
        if (compoundError != _COMPOUND_SUCCESS) {
          emit ExternalError(
            address(_CDAI),
            string(
              abi.encodePacked(
                "Compound cDAI contract returned error code ",
                uint8((compoundError / 10) + 48),
                uint8((compoundError % 10) + 48),
                " while attempting to deposit dai."
              )
            )
          );
        }
      } else {
        emit ExternalError(
          address(_CDAI),
          string(
            abi.encodePacked("Compound cDAI contract reverted on mint: ", data)
          )
        );
      }
    }
  }

  function _borrowDaiFromCompound(
    uint256 daiToBorrow
  ) internal returns (bool success) {
    // Attempt to borrow the Dai amount from the cDAI contract.
    (bool ok, bytes memory data) = address(_CDAI).call(abi.encodeWithSelector(
      _CDAI.borrow.selector, daiToBorrow
    ));

    // Log an external error if something went wrong with the attempt.
    if (ok) {
      uint256 compoundError = abi.decode(data, (uint256));
      if (compoundError != _COMPOUND_SUCCESS) {
        emit ExternalError(
          address(_CDAI),
          string(
            abi.encodePacked(
              "Compound cDAI contract returned error code ",
              uint8((compoundError / 10) + 48),
              uint8((compoundError % 10) + 48),
              " while attempting to borrow Dai."
            )
          )
        );
      } else {
        success = true;
      }
    } else {
      emit ExternalError(
        address(_CDAI),
        string(
          abi.encodePacked(
            "Compound cDAI contract reverted on borrow: ",
            data
          )
        )
      );
    }
  }

  function _withdrawEtherFromCompound(
    uint256 etherToWithdraw
  ) internal returns (bool success) {
    // Attempt to mint the Dai balance on the cEther contract.
    (bool ok, bytes memory data) = address(_CETH).call(abi.encodeWithSelector(
      _CETH.redeemUnderlying.selector, etherToWithdraw
    ));

    // Log an external error if something went wrong with the attempt.
    if (ok) {
      uint256 compoundError = abi.decode(data, (uint256));
      if (compoundError != _COMPOUND_SUCCESS) {
        emit ExternalError(
          address(_CETH),
          string(
            abi.encodePacked(
              "Compound cEther contract returned error code ",
              uint8((compoundError / 10) + 48),
              uint8((compoundError % 10) + 48),
              " while attempting to redeem Ether."
            )
          )
        );
      } else {
        success = true;
      }
    } else {
      emit ExternalError(
        address(_CETH),
        string(
          abi.encodePacked(
            "Compound cEther contract reverted on redeemUnderlying: ",
            data
          )
        )
      );
    }
  }

  function _withdrawDaiFromCompound(
    uint256 daiToWithdraw
  ) internal returns (bool success) {
    // Attempt to mint the Dai balance on the cDAI contract.
    (bool ok, bytes memory data) = address(_CDAI).call(abi.encodeWithSelector(
      _CDAI.redeemUnderlying.selector, daiToWithdraw
    ));

    // Log an external error if something went wrong with the attempt.
    if (ok) {
      uint256 compoundError = abi.decode(data, (uint256));
      if (compoundError != _COMPOUND_SUCCESS) {
        emit ExternalError(
          address(_CDAI),
          string(
            abi.encodePacked(
              "Compound cDAI contract returned error code ",
              uint8((compoundError / 10) + 48),
              uint8((compoundError % 10) + 48),
              " while attempting to redeem Dai."
            )
          )
        );
      } else {
        success = true;
      }
    } else {
      emit ExternalError(
        address(_CDAI),
        string(
          abi.encodePacked(
            "Compound cDAI contract reverted on redeemUnderlying: ",
            data
          )
        )
      );
    }
  }

  function _repayUSDCOnCompound(
    uint256 usdcBalance
  ) internal returns (uint256 remainingUsdcBalance) {
    // TODO: handle errors originating from this call (reverts on MathError).
    uint256 usdcBorrowBalance = _CUSDC.borrowBalanceCurrent(address(this));

    // Skip repayment if there is no borrow balance.
    if (usdcBorrowBalance == 0) {
      return usdcBalance;
    }

    uint256 usdcBorrowBalanceToRepay;
    if (usdcBorrowBalance > usdcBalance) {
      usdcBorrowBalanceToRepay = usdcBalance;
    } else {
      usdcBorrowBalanceToRepay = usdcBorrowBalance;
    }
    // Note: SafeMath not needed since usdcBalance >= usdcBorrowBalanceToRepay
    remainingUsdcBalance = usdcBalance - usdcBorrowBalanceToRepay;

    // Attempt to repay the Dai balance on the cUSDC contract.
    (bool ok, bytes memory data) = address(_CUSDC).call(abi.encodeWithSelector(
      _CUSDC.repayBorrow.selector, usdcBorrowBalanceToRepay
    ));

    // Log an external error if something went wrong with the attempt.
    if (ok) {
      uint256 compoundError = abi.decode(data, (uint256));
      if (compoundError != _COMPOUND_SUCCESS) {
        emit ExternalError(
          address(_CUSDC),
          string(
            abi.encodePacked(
              "Compound cUSDC contract returned error code ",
              uint8((compoundError / 10) + 48),
              uint8((compoundError % 10) + 48),
              " while attempting to repay USDC borrow."
            )
          )
        );
        remainingUsdcBalance = usdcBalance;
      }
    } else {
      emit ExternalError(
        address(_CUSDC),
        string(
          abi.encodePacked("Compound cUSDC contract reverted on repay: ", data)
        )
      );
      remainingUsdcBalance = usdcBalance;
    }
  }

  function _depositUSDCOnCompound(uint256 usdcBalance) internal {
    if (usdcBalance > 0) {
      // Attempt to mint the USDC balance on the cUSDC contract.
      (bool ok, bytes memory data) = address(_CUSDC).call(abi.encodeWithSelector(
        _CUSDC.mint.selector, usdcBalance
      ));

      // Log an external error if something went wrong with the attempt.
      if (ok) {
        uint256 compoundError = abi.decode(data, (uint256));
        if (compoundError != _COMPOUND_SUCCESS) {
          emit ExternalError(
            address(_CUSDC),
            string(
              abi.encodePacked(
                "Compound cUSDC contract returned error code ",
                uint8((compoundError / 10) + 48),
                uint8((compoundError % 10) + 48),
                " while attempting to deposit USDC."
              )
            )
          );
        }
      } else {
        emit ExternalError(
          address(_CUSDC),
          string(
            abi.encodePacked("Compound cUSDC contract reverted on mint: ", data)
          )
        );
      }
    }
  }

  function _depositEtherOnCompound() internal {
    uint256 balance = address(this).balance;
    if (balance > 0) {
      // Attempt to mint the full ETH balance on the cEther contract.
      (bool ok, bytes memory data) = address(_CETH).call.value(balance)(
        abi.encodeWithSelector(_CETH.mint.selector)
      );

      // Log an external error if something went wrong with the attempt.
      if (!ok) {
        emit ExternalError(
          address(_CETH),
          string(
            abi.encodePacked("Compound cEther contract reverted on mint: ", data)
          )
        );
      }
    }
  }

  function _borrowUSDCFromCompound(
    uint256 usdcToBorrow
  ) internal returns (bool success) {
    // Attempt to borrow the USDC amount from the cUSDC contract.
    (bool ok, bytes memory data) = address(_CUSDC).call(abi.encodeWithSelector(
      _CUSDC.borrow.selector, usdcToBorrow
    ));

    // Log an external error if something went wrong with the attempt.
    if (ok) {
      uint256 compoundError = abi.decode(data, (uint256));
      if (compoundError != _COMPOUND_SUCCESS) {
        emit ExternalError(
          address(_CUSDC),
          string(
            abi.encodePacked(
              "Compound cUSDC contract returned error code ",
              uint8((compoundError / 10) + 48),
              uint8((compoundError % 10) + 48),
              " while attempting to borrow USDC."
            )
          )
        );
      } else {
        success = true;
      }
    } else {
      emit ExternalError(
        address(_CUSDC),
        string(
          abi.encodePacked(
            "Compound cUSDC contract reverted on borrow: ",
            data
          )
        )
      );
    }
  }

  function _withdrawUSDCFromCompound(
    uint256 usdcToWithdraw
  ) internal returns (bool success) {
    // Attempt to mint the Dai balance on the cDAI contract.
    (bool ok, bytes memory data) = address(_CDAI).call(abi.encodeWithSelector(
      _CUSDC.redeemUnderlying.selector, usdcToWithdraw
    ));

    // Log an external error if something went wrong with the attempt.
    if (ok) {
      uint256 compoundError = abi.decode(data, (uint256));
      if (compoundError != _COMPOUND_SUCCESS) {
        emit ExternalError(
          address(_CDAI),
          string(
            abi.encodePacked(
              "Compound cUSDC contract returned error code ",
              uint8((compoundError / 10) + 48),
              uint8((compoundError % 10) + 48),
              " while attempting to redeem USDC."
            )
          )
        );
      } else {
        success = true;
      }
    } else {
      emit ExternalError(
        address(_CUSDC),
        string(
          abi.encodePacked(
            "Compound cUSDC contract reverted on redeemUnderlying: ",
            data
          )
        )
      );
    }
  }

  function _setFullUSDCApproval() internal returns (bool ok) {
    // Approve the cUSDC contract to transfer USDC on behalf of this contract.
    (ok, ) = address(_USDC).call(abi.encodeWithSelector(
      _USDC.approve.selector, address(_CUSDC), uint256(-1)
    ));

    // If the USDC approval failed, find out *why* it failed and log it.
    if (!ok) {
      if (_USDC_NAUGHTY.isBlacklisted(address(this))) {
        emit ExternalError(
          address(_USDC),
          "approval failed - USDC has blacklisted this user."
        );
      }
      if (_USDC_NAUGHTY.paused()) {
        emit ExternalError(
          address(_USDC),
          "approval failed - USDC contract is currently paused."
        );
      } else {
        emit ExternalError(address(_USDC), "USDC approval failed.");        
      }
    }
  }

  function _enterMarkets() internal {
    address[] memory marketsToEnter = new address[](3);
    marketsToEnter[0] = address(_CDAI);
    marketsToEnter[1] = address(_CUSDC);
    marketsToEnter[2] = address(_CETH);

    // Attempt to mint the USDC balance on the cUSDC contract.
    (bool ok, bytes memory data) = address(_COMPTROLLER).call(abi.encodeWithSelector(
      _COMPTROLLER.enterMarkets.selector, marketsToEnter
    ));

    // Log an external error if something went wrong with the attempt.
    if (ok) {
      uint256[] memory compoundErrors = abi.decode(data, (uint256[]));
      for (uint256 i = 0; i < compoundErrors.length; i++) {
        uint256 compoundError = compoundErrors[i];
        if (compoundError != _COMPOUND_SUCCESS) {
          emit ExternalError(
            address(_COMPTROLLER),
            string(
              abi.encodePacked(
                "Compound comptroller contract returned error code ",
                uint8((compoundError / 10) + 48),
                uint8((compoundError % 10) + 48),
                " while attempting to enter a market."
              )
            )
          );
        }
      }
    } else {
      emit ExternalError(
        address(_COMPTROLLER),
        string(
          abi.encodePacked(
            "Compound comptroller contract reverted on enterMarkets: ",
            data
          )
        )
      );
    }
  }

  function _validateCustomActionAndIncrementNonce(
    ActionType actionType,
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes memory dharmaKeySignature,
    bytes memory dharmaSecondaryKeySignature
  ) internal returns (bytes32 actionID) {
    // Ensure that the action has the correct nonce.
    require(_nonce == nonce, "Invalid action - incorrect nonce.");

    // Determine the actionID - this serves as the signature hash.
    actionID = _getCustomActionID(actionType, amount, recipient, nonce, minimumActionGas);

    _verifySignaturesAndIncrementNonce(
      actionID,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Ensure that the current gas exceeds the minimum required action gas.
    // This prevents griefing attacks where an attacker can invalidate a
    // signature without providing enough gas for the action to succeed.
    // To skip this requirement, supply zero for the minimumActionGas argument.
    require(
      gasleft() >= minimumActionGas,
      "Invalid action - insufficient gas supplied by transaction submitter."
    );
  }

  function _validateActionAndIncrementNonce(
    address to,
    bytes memory data,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes memory dharmaKeySignature,
    bytes memory dharmaSecondaryKeySignature
  ) internal returns (bytes32 actionID) {
    // Ensure that the action has the correct nonce.
    require(_nonce == nonce, "Invalid action - incorrect nonce.");

    // Ensure that the `to` address is a contract.
    require(
      to.isContract(),
      "Invalid action - must supply a contract as the `to` argument."
    );

    // Determine the actionID - this serves as the signature hash.
    actionID = _getGenericActionID(to, data, nonce, minimumActionGas);

    _verifySignaturesAndIncrementNonce(
      actionID,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Ensure that the current gas exceeds the minimum required action gas.
    // This prevents griefing attacks where an attacker can invalidate a
    // signature without providing enough gas for the action to succeed.
    // To skip this requirement, supply zero for the minimumActionGas argument.
    require(
      gasleft() >= minimumActionGas,
      "Invalid action - insufficient gas supplied by transaction submitter."
    );
  }

  function _validateActionWithAtomicBatchCallsAndIncrementNonce(
    Call[] memory calls,
    uint256 nonce,
    uint256 minimumActionGas,
    bytes memory dharmaKeySignature,
    bytes memory dharmaSecondaryKeySignature
  ) internal returns (bytes32 actionID) {
    // Ensure that the action has the correct nonce.
    require(_nonce == nonce, "Invalid action - incorrect nonce.");

    // Ensure that the `to` address is a contract for each call.
    for (uint256 i = 0; i < calls.length; i++) {
      require(
        calls[i].to.isContract(),
        "Invalid action - must supply a contract for each `to` argument."
      );
    }

    // Determine the actionID - this serves as the signature hash.
    actionID = _getGenericAtomicBatchActionID(calls, nonce, minimumActionGas);

    _verifySignaturesAndIncrementNonce(
      actionID,
      dharmaKeySignature,
      dharmaSecondaryKeySignature
    );

    // Ensure that the current gas exceeds the minimum required action gas.
    // This prevents griefing attacks where an attacker can invalidate a
    // signature without providing enough gas for the action to succeed.
    require(
      gasleft() >= minimumActionGas,
      "Invalid action - insufficient gas supplied by transaction submitter."
    );
  }

  function _verifySignaturesAndIncrementNonce(
    bytes32 actionID,
    bytes memory dharmaKeySignature,
    bytes memory dharmaSecondaryKeySignature
  ) internal {
    // Place the dharma key into memory to avoid repeated SLOAD operations.
    address dharmaKey = _dharmaKey;

    // First, validate the Dharma Key signature unless it is `msg.sender`.
    if (msg.sender != dharmaKey) {
      require(
        dharmaKey != address(0) &&
        dharmaKey == actionID.toEthSignedMessageHash().recover(
          dharmaKeySignature
        ),
        "Invalid action - invalid Dharma Key signature."
      );
    }

    // Next, validate Dharma Secondary Key signature unless it is `msg.sender`.
    if (msg.sender != _DHARMA_SECONDARY_KEY) {
      require(
        _DHARMA_SECONDARY_KEY == actionID.toEthSignedMessageHash().recover(
          dharmaSecondaryKeySignature
        ),
        "Invalid action - invalid Dharma Secondary Key signature."
      );
    }

    // Increment nonce in order to prevent reuse of signatures after the call.
    _nonce++;
  }

  function _getGenericActionID(
    address to,
    bytes memory data,
    uint256 nonce,
    uint256 minimumActionGas
  ) internal view returns (bytes32 actionID) {
    // The actionID is constructed according to EIP-191-0x45 to prevent replays.
    actionID = keccak256(
      abi.encodePacked(
        address(this),
        _DHARMA_SMART_WALLET_VERSION,
        _dharmaKey,
        _DHARMA_SECONDARY_KEY,
        nonce,
        minimumActionGas,
        ActionType.Generic,
        to,
        data
      )
    );
  }

  function _getGenericAtomicBatchActionID(
    Call[] memory calls,
    uint256 nonce,
    uint256 minimumActionGas
  ) internal view returns (bytes32 actionID) {
    // The actionID is constructed according to EIP-191-0x45 to prevent replays.
    actionID = keccak256(
      abi.encodePacked(
        address(this),
        _DHARMA_SMART_WALLET_VERSION,
        _dharmaKey,
        _DHARMA_SECONDARY_KEY,
        nonce,
        minimumActionGas,
        ActionType.GenericAtomicBatch,
        abi.encode(calls)
      )
    );
  }

  function _getCustomActionID(
    ActionType actionType,
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) internal view returns (bytes32 actionID) {
    // The actionID is constructed according to EIP-191-0x45 to prevent replays.
    actionID = keccak256(
      abi.encodePacked(
        address(this),
        _DHARMA_SMART_WALLET_VERSION,
        _dharmaKey,
        _DHARMA_SECONDARY_KEY,
        nonce,
        minimumActionGas,
        actionType,
        amount,
        recipient
      )
    );
  }
}
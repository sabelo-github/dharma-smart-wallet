var assert = require('assert')
var fs = require('fs')
var util = require('ethereumjs-util')

const DharmaAccountRecoveryMultisigArtifact = require('../../build/contracts/DharmaAccountRecoveryMultisig.json')
const DharmaUpgradeBeaconArtifact = require('../../build/contracts/DharmaUpgradeBeacon.json')
const DharmaUpgradeBeaconControllerArtifact = require('../../build/contracts/DharmaUpgradeBeaconController.json')
const DharmaUpgradeBeaconControllerManagerArtifact = require('../../build/contracts/DharmaUpgradeBeaconControllerManager.json')
const DharmaUpgradeMultisigArtifact = require('../../build/contracts/DharmaUpgradeMultisig.json')

const UpgradeBeaconProxyArtifact = require('../../build/contracts/UpgradeBeaconProxy.json')
const DharmaSmartWalletFactoryV1Artifact = require('../../build/contracts/DharmaSmartWalletFactoryV1.json')
const DharmaSmartWalletImplementationV0Artifact = require('../../build/contracts/DharmaSmartWalletImplementationV0.json')
const DharmaSmartWalletImplementationV1Artifact = require('../../build/contracts/DharmaSmartWalletImplementationV1.json')

const UpgradeBeaconImplementationCheckArtifact = require('../../build/contracts/UpgradeBeaconImplementationCheck.json')
const MockCodeCheckArtifact = require('../../build/contracts/MockCodeCheck.json')
const IERC20Artifact = require('../../build/contracts/IERC20.json')

const nullAddress = '0x0000000000000000000000000000000000000000'
const nullBytes32 = '0x0000000000000000000000000000000000000000000000000000000000000000'
const emptyHash = '0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470'
const FULL_APPROVAL = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

const keylessCreate2DeployerAddress = '0x4c8D290a1B368ac4728d83a9e8321fC3af2b39b1'
const keylessCreate2DeploymentTransaction = '0xf87e8085174876e800830186a08080ad601f80600e600039806000f350fe60003681823780368234f58015156014578182fd5b80825250506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222'
const keylessCreate2Address = '0x7A0D94F55792C434d74a40883C6ed8545E406D12'

const eth_whale = '0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe'
const dai_whale = '0x76B03EB651153a81fA1f212f2f59329B4180A46F'
const usdc_whale = '0x035e742A7E62253C606b9028eeB65178B44F1e7E'

const DAI_MAINNET_ADDRESS = '0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359'
const USDC_MAINNET_ADDRESS = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
const CDAI_MAINNET_ADDRESS = '0xF5DCe57282A584D2746FaF1593d3121Fcac444dC'
const CUSDC_MAINNET_ADDRESS = '0x39AA39c021dfbaE8faC545936693aC917d5E7563'
const CETH_MAINNET_ADDRESS = '0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5'
const COMPTROLLER_MAINNET_ADDRESS = '0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B'

const contractNames = {}
contractNames[DAI_MAINNET_ADDRESS] = 'DAI'
contractNames[USDC_MAINNET_ADDRESS] = 'USDC'
contractNames[CDAI_MAINNET_ADDRESS] = 'CDAI'
contractNames[CUSDC_MAINNET_ADDRESS] = 'CUSDC'
contractNames[CETH_MAINNET_ADDRESS] = 'CETH'
contractNames[COMPTROLLER_MAINNET_ADDRESS] = 'Comptroller'

// keccak256 of NewDharmaKey(address) -> dharmaKey
const NEW_DHARMA_KEY_TOPIC = '0xc85cb9f33f88ea30edde920e5b888fbfbb6c8d84054c2ecc53ace52a7df75cdb'
const NEW_DHARMA_KEY_ABI = [
  {
    type: 'address',
    name: 'dharmaKey'
  }
]

// keccak256 of ExternalError(address,string) -> source, revertReason
const EXTERNAL_ERROR_TOPIC = '0x5bbd5ab79029b89a22c80c7b7bfdc2f0c8e3f0d2a7330c7148cabc044250674b'
const EXTERNAL_ERROR_ABI = [
  {
    type: 'address',
    name: 'source',
    indexed: true
  }, {
    type: 'string',
    name: 'revertReason'
  }
]

// keccak256 of SmartWalletDeployed(address,address) -> wallet, dharmaKey
const SMART_WALLET_DEPLOYED_TOPIC = '0x6e60d84846384a1994833ed675b0a0f76bef64943304debf6e42a9706d1a7dd7'
const SMART_WALLET_DEPLOYED_ABI = [
  {
    type: 'address',
    name: 'wallet'
  }, {
    type: 'address',
    name: 'dharmaKey'
  }
]

// keccak256 of Approval(address,address,uint256) -> owner, spender, value
const APPROVAL_TOPIC = '0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925'
const APPROVAL_ABI = [
  {
    type: 'address',
    name: 'owner',
    indexed: true
  }, {
    type: 'address',
    name: 'spender',
    indexed: true
  }, {
    type: 'uint256',
    name: 'value'
  }
]

// keccak256 of Transfer(address,address,uint256) -> to, from, value
const TRANSFER_TOPIC = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
const TRANSFER_ABI = [
  {
    type: 'address',
    name: 'from',
    indexed: true
  }, {
    type: 'address',
    name: 'to',
    indexed: true
  }, {
    type: 'uint256',
    name: 'value'
  }
]

// keccak256 of Mint(address,uint256,uint256) -> minter, mintTokens, mintAmount
const MINT_TOPIC = '0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f'
const MINT_ABI = [
  {
    type: 'address',
    name: 'minter'
  }, {
    type: 'uint256',
    name: 'mintTokens'
  }, {
    type: 'uint256',
    name: 'mintAmount'
  }
]

// keccak256 of Redeem(address,uint256,uint256) -> redeemer, redeemTokens, redeemAmount
const REDEEM_TOPIC = '0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929'
const REDEEM_ABI = [
  {
    type: 'address',
    name: 'redeemer'
  }, {
    type: 'uint256',
    name: 'redeemTokens'
  }, {
    type: 'uint256',
    name: 'redeemAmount'
  }
]

// keccak256 of MarketEntered(address,address) -> cToken, account
const MARKET_ENTERED_TOPIC = '0x3ab23ab0d51cccc0c3085aec51f99228625aa1a922b3a8ca89a26b0f2027a1a5'
const MARKET_ENTERED_ABI = [
  {
    type: 'address',
    name: 'cToken'
  }, {
    type: 'address',
    name: 'account'
  }
]

// keccak256 of AccrueInterest(uint256,uint256,uint256) -> interestAccumulated, borrowIndex, totalBorrows
const ACCRUE_INTEREST_TOPIC = '0x875352fb3fadeb8c0be7cbbe8ff761b308fa7033470cd0287f02f3436fd76cb9'
const ACCRUE_INTEREST_ABI = [
  {
    type: 'uint256',
    name: 'interestAccumulated'
  }, {
    type: 'uint256',
    name: 'borrowIndex'
  }, {
    type: 'uint256',
    name: 'totalBorrows'
  }
]

const eventDetails = {}
eventDetails[NEW_DHARMA_KEY_TOPIC] = {
  name: 'NewDharmaKey',
  abi: NEW_DHARMA_KEY_ABI
}
eventDetails[EXTERNAL_ERROR_TOPIC] = {
  name: 'ExternalError',
  abi: EXTERNAL_ERROR_ABI
}
eventDetails[SMART_WALLET_DEPLOYED_TOPIC] = {
  name: 'SmartWalletDeployed',
  abi: SMART_WALLET_DEPLOYED_ABI
}
eventDetails[APPROVAL_TOPIC] = {
  name: 'Approval',
  abi: APPROVAL_ABI
}
eventDetails[TRANSFER_TOPIC] = {
  name: 'Transfer',
  abi: TRANSFER_ABI
}
eventDetails[MINT_TOPIC] = {
  name: 'Mint',
  abi: MINT_ABI
}
eventDetails[REDEEM_TOPIC] = {
  name: 'Redeem',
  abi: REDEEM_ABI
}
eventDetails[MARKET_ENTERED_TOPIC] = {
  name: 'MarketEntered',
  abi: MARKET_ENTERED_ABI
}
eventDetails[ACCRUE_INTEREST_TOPIC] = {
  name: 'AccrueInterest',
  abi: ACCRUE_INTEREST_ABI
}

// used to wait for more confirmations
function longer() {
  return new Promise(resolve => {setTimeout(() => {resolve()}, 500)})
}

module.exports = {test: async function (provider, testingContext) {
  var web3 = provider
  let passed = 0
  let failed = 0
  let gasUsage = {}
  let counts = {}
  console.log('running tests...')

  // get available addresses and assign them to various roles
  const addresses = await web3.eth.getAccounts()
  if (addresses.length < 1) {
    console.log('cannot find enough addresses to run tests!')
    process.exit(1)
  }

  const originalAddress = addresses[0]

  // ************************** helper functions **************************** //
  async function send(
    title,
    instance,
    method,
    args,
    from,
    value,
    gas,
    gasPrice,
    shouldSucceed,
    assertionCallback
  ) {
    const receipt = await instance.methods[method](...args).send({
      from: from,
      value: value,
      gas: gas,
      gasPrice: gasPrice
    }).on('confirmation', (confirmationNumber, r) => {
      confirmations[r.transactionHash] = confirmationNumber
    }).catch(error => {
      if (shouldSucceed) {
        console.error(error)
      }
      return {status: false}
    })

    if (receipt.status !== shouldSucceed) {
      return false
    } else if (!shouldSucceed) {
      return true
    }

    let assertionsPassed
    try {
      assertionCallback(receipt)
      assertionsPassed = true
    } catch(error) {
      assertionsPassed = false
      console.log(error);
    }

    return assertionsPassed
  }

  async function call(
    title,
    instance,
    method,
    args,
    from,
    value,
    gas,
    gasPrice,
    shouldSucceed,
    assertionCallback
  ) {
    let succeeded = true
    returnValues = await instance.methods[method](...args).call({
      from: from,
      value: value,
      gas: gas,
      gasPrice: gasPrice
    }).catch(error => {
      if (shouldSucceed) {
        console.error(error)
      }
      succeeded = false
    })

    if (succeeded !== shouldSucceed) {
      return false
    } else if (!shouldSucceed) {
      return true
    }

    let assertionsPassed
    try {
      assertionCallback(returnValues)
      assertionsPassed = true
    } catch(error) {
      assertionsPassed = false
      console.log(error);
    }

    return assertionsPassed
  }

  async function deploy(
    title,
    instance,
    args,
    from,
    value,
    gas,
    gasPrice,
    shouldSucceed,
    assertionCallback
  ) {
    let deployData = instance.deploy({arguments: args}).encodeABI()
    let deployGas = await web3.eth.estimateGas({
        from: from,
        data: deployData
    }).catch(error => {
      if (shouldSucceed) {
        console.error(error)
      }
      return gasLimit
    })

    if (deployGas > gasLimit) {
      console.error(` ✘ ${title}: deployment costs exceed block gas limit!`)
      process.exit(1)
    }

    if (typeof(gas) === 'undefined') {
      gas = deployGas
    }

    if (deployGas > gas) {
      console.error(` ✘ ${title}: deployment costs exceed supplied gas.`)
      process.exit(1)
    }

    let signed
    let deployHash
    let receipt
    const contract = await instance.deploy({arguments: args}).send({
      from: from,
      gas: gas,
      gasPrice: gasPrice
    }).on('transactionHash', hash => {
      deployHash = hash
    }).on('receipt', r => {
      receipt = r
    }).on('confirmation', (confirmationNumber, r) => {
      confirmations[r.transactionHash] = confirmationNumber
    }).catch(error => {
      if (shouldSucceed) {
        console.error(error)
      }

      receipt = {status: false}
    })

    if (receipt.status !== shouldSucceed) {
      if (contract) {
        return [false, contract, gas]
      }
      return [false, instance, gas]
    } else if (!shouldSucceed) {
      if (contract) {
        return [true, contract, gas]
      }
      return [true, instance, gas]
    }

    assert.ok(receipt.status)

    let assertionsPassed
    try {
      assertionCallback(receipt)
      assertionsPassed = true
    } catch(error) {
      assertionsPassed = false
    }

    if (contract) {
      return [assertionsPassed, contract, gas]
    }
    return [assertionsPassed, instance, gas]
  }

  async function runTest(
    title,
    instance,
    method,
    callOrSend,
    args,
    shouldSucceed,
    assertionCallback,
    from,
    value,
    gas
  ) {
    if (typeof(callOrSend) === 'undefined') {
      callOrSend = 'send'
    }
    if (typeof(args) === 'undefined') {
      args = []
    }
    if (typeof(shouldSucceed) === 'undefined') {
      shouldSucceed = true
    }
    if (typeof(assertionCallback) === 'undefined') {
      assertionCallback = (value) => {}
    }
    if (typeof(from) === 'undefined') {
      from = address
    }
    if (typeof(value) === 'undefined') {
      value = 0
    }
    if (typeof(gas) === 'undefined' && callOrSend !== 'deploy') {
      gas = 6009006
      if (testingContext === 'coverage') {
        gas = gasLimit - 1
      }
    }
    let ok = false
    let contract
    let deployGas
    if (callOrSend === 'send') {
      ok = await send(
        title,
        instance,
        method,
        args,
        from,
        value,
        gas,
        1,
        shouldSucceed,
        assertionCallback
      )
    } else if (callOrSend === 'call') {
      ok = await call(
        title,
        instance,
        method,
        args,
        from,
        value,
        gas,
        1,
        shouldSucceed,
        assertionCallback
      )
    } else if (callOrSend === 'deploy') {
      const fields = await deploy(
        title,
        instance,
        args,
        from,
        value,
        gas,
        1,
        shouldSucceed,
        assertionCallback
      )
      ok = fields[0]
      contract = fields[1]
      deployGas = fields[2]
    } else {
      console.error('must use call, send, or deploy!')
      process.exit(1)
    }

    if (ok) {
      console.log(
        ` ✓ ${
          callOrSend === 'deploy' ? 'successful ' : ''
        }${title}${
          callOrSend === 'deploy' ? ` (${deployGas} gas)` : ''
        }`
      )
      passed++
    } else {
      console.log(
        ` ✘ ${
          callOrSend === 'deploy' ? 'failed ' : ''
        }${title}${
          callOrSend === 'deploy' ? ` (${deployGas} gas)` : ''
        }`
      )
      failed++
    }

    if (contract) {
      return contract
    }
  }

  async function setupNewDefaultAddress(newPrivateKey) {
    const pubKey = await web3.eth.accounts.privateKeyToAccount(newPrivateKey)
    await web3.eth.accounts.wallet.add(pubKey)

    const txCount = await web3.eth.getTransactionCount(pubKey.address)

    if (txCount > 0) {
      console.warn(
        `warning: ${pubKey.address} has already been used, which may cause ` +
        'some tests to fail.'
      )
    }

    await web3.eth.sendTransaction({
      from: originalAddress,
      to: pubKey.address,
      value: 10 ** 18,
      gas: '0x5208',
      gasPrice: '0x4A817C800'
    })

    return pubKey.address
  }

  async function raiseGasLimit(necessaryGas) {
    iterations = 9999
    if (necessaryGas > 8000000) {
      console.error('the gas needed is too high!')
      process.exit(1)
    } else if (typeof necessaryGas === 'undefined') {
      iterations = 20
      necessaryGas = 8000000
    }

    // bring up gas limit if necessary by doing additional transactions
    var block = await web3.eth.getBlock("latest")
    while (iterations > 0 && block.gasLimit < necessaryGas) {
      await web3.eth.sendTransaction({
        from: originalAddress,
        to: originalAddress,
        value: '0x01',
        gas: '0x5208',
        gasPrice: '0x4A817C800'
      })
      var block = await web3.eth.getBlock("latest")
      iterations--
    }

    console.log("raising gasLimit, currently at " + block.gasLimit)
    return block.gasLimit
  }

  async function getDeployGas(dataPayload) {
    await web3.eth.estimateGas({
      from: address,
      data: dataPayload
    }).catch(async error => {
      if (
        error.message === (
          'Returned error: gas required exceeds allowance or always failing ' +
          'transaction'
        )
      ) {
        await raiseGasLimit()
        await getDeployGas(dataPayload)
      }
    })

    deployGas = await web3.eth.estimateGas({
      from: address,
      data: dataPayload
    })

    return deployGas
  }

  // *************************** deploy contracts *************************** //
  let address = await setupNewDefaultAddress(
    '0xfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeed'
  )

  let deployGas
  let latestBlock = await web3.eth.getBlock('latest')
  const gasLimit = latestBlock.gasLimit
  let selfAddress

  // fund the initial create2 deployer address
  console.log('funding initial create2 contract deployer address...')
  await web3.eth.sendTransaction({
    from: originalAddress,
    to: keylessCreate2DeployerAddress,
    value: web3.utils.toWei('0.01', 'ether'),
    gas: (testingContext !== 'coverage') ? '0x5208' : gasLimit - 1,
    gasPrice: 1
  })

  // submit the initial create2 deployment transaction if needed
  console.log('submitting initial create2 contract deployment transaction...')
  await web3.eth.sendSignedTransaction(keylessCreate2DeploymentTransaction)
    .catch(error => {console.log('skipping...')}
  );

  // construct the payload passed to create2 in order to verify correct behavior
  let create2payload = (
    '0xff' +
    keylessCreate2Address.slice(2) +
    '0000000000000000000000000000000000000000000000000000000000000000' +
    web3.utils.keccak256(
      MockCodeCheckArtifact.bytecode,
      {encoding: 'hex'}
    ).slice(2)
  )

  // determine the target address using the payload
  let targetCodeCheckAddress = web3.utils.toChecksumAddress(
    '0x' + web3.utils.keccak256(
      create2payload,
      {encoding: "hex"}
    ).slice(12).substring(14)
  )

  // deploy a mock code check contract using the initial create2 deployer
  console.log('deploying test contract via create2 contract...')
  const DeploymentTx = await web3.eth.sendTransaction({
    from: originalAddress,
    to: keylessCreate2Address,
    value: 0,
    gas: (testingContext !== 'coverage') ? 1500051 : gasLimit - 1,
    gasPrice: 1,
    data: MockCodeCheckArtifact.bytecode
  })

  const DharmaAccountRecoveryMultisigDeployer = new web3.eth.Contract(
    DharmaAccountRecoveryMultisigArtifact.abi
  )
  DharmaAccountRecoveryMultisigDeployer.options.data = (
    DharmaAccountRecoveryMultisigArtifact.bytecode
  )

  const DharmaUpgradeBeaconControllerDeployer = new web3.eth.Contract(
    DharmaUpgradeBeaconControllerArtifact.abi
  )
  DharmaUpgradeBeaconControllerDeployer.options.data = (
    DharmaUpgradeBeaconControllerArtifact.bytecode
  )

  const DharmaUpgradeBeaconDeployer = new web3.eth.Contract(
    DharmaUpgradeBeaconArtifact.abi
  )
  DharmaUpgradeBeaconDeployer.options.data = (
    DharmaUpgradeBeaconArtifact.bytecode
  )

  const DharmaUpgradeBeaconControllerManagerDeployer = new web3.eth.Contract(
    DharmaUpgradeBeaconControllerManagerArtifact.abi
  )
  DharmaUpgradeBeaconControllerManagerDeployer.options.data = (
    DharmaUpgradeBeaconControllerManagerArtifact.bytecode
  )

  const DharmaUpgradeMultisigDeployer = new web3.eth.Contract(
    DharmaUpgradeMultisigArtifact.abi
  )
  DharmaUpgradeMultisigDeployer.options.data = (
    DharmaUpgradeMultisigArtifact.bytecode
  )

  const DharmaSmartWalletFactoryV1Deployer = new web3.eth.Contract(
    DharmaSmartWalletFactoryV1Artifact.abi
  )
  DharmaSmartWalletFactoryV1Deployer.options.data = (
    DharmaSmartWalletFactoryV1Artifact.bytecode
  )

  const DharmaSmartWalletImplementationV0Deployer = new web3.eth.Contract(
    DharmaSmartWalletImplementationV0Artifact.abi
  )
  DharmaSmartWalletImplementationV0Deployer.options.data = (
    DharmaSmartWalletImplementationV0Artifact.bytecode
  )

  const DharmaSmartWalletImplementationV1Deployer = new web3.eth.Contract(
    DharmaSmartWalletImplementationV1Artifact.abi
  )
  DharmaSmartWalletImplementationV1Deployer.options.data = (
    DharmaSmartWalletImplementationV1Artifact.bytecode
  )

  const UpgradeBeaconImplementationCheckDeployer = new web3.eth.Contract(
    UpgradeBeaconImplementationCheckArtifact.abi
  )
  UpgradeBeaconImplementationCheckDeployer.options.data = (
    UpgradeBeaconImplementationCheckArtifact.bytecode
  )

  const MockCodeCheckDeployer = new web3.eth.Contract(
    MockCodeCheckArtifact.abi
  )
  MockCodeCheckDeployer.options.data = (
    MockCodeCheckArtifact.bytecode
  )

  const MockCodeCheckTwo = new web3.eth.Contract(
    MockCodeCheckArtifact.abi,
    targetCodeCheckAddress
  )

  const DAI = new web3.eth.Contract(IERC20Artifact.abi, DAI_MAINNET_ADDRESS)

  const USDC = new web3.eth.Contract(IERC20Artifact.abi, USDC_MAINNET_ADDRESS)

  const CDAI = new web3.eth.Contract(IERC20Artifact.abi, CDAI_MAINNET_ADDRESS)

  const CUSDC = new web3.eth.Contract(IERC20Artifact.abi, CUSDC_MAINNET_ADDRESS)

  const MockCodeCheck = await runTest(
    `MockCodeCheck contract deployment`,
    MockCodeCheckDeployer,
    '',
    'deploy'
  )

  await runTest(
    'Deployed MockCodeCheck code is correct',
    MockCodeCheck,
    'code',
    'call',
    [MockCodeCheck.options.address],
    true,
    value => {
      assert.strictEqual(value, MockCodeCheckArtifact.deployedBytecode)
    }
  )

  await runTest(
    'Deployed MockCodeCheck has correct extcodehash',
    MockCodeCheck,
    'hash',
    'call',
    [MockCodeCheck.options.address],
    true,
    value => {
      assert.strictEqual(
        value,
        web3.utils.keccak256(
          MockCodeCheckArtifact.deployedBytecode,
          {encoding: 'hex'}
        )
      )
    }
  )

  // BEGIN ACTUAL DEPLOYMENT TESTS
  const DharmaUpgradeMultisig = await runTest(
    `DharmaUpgradeMultisig contract deployment`,
    DharmaUpgradeMultisigDeployer,
    '',
    'deploy',
    [[address], 1]
  )

  const DharmaAccountRecoveryMultisig = await runTest(
    `DharmaAccountRecoveryMultisig contract deployment`,
    DharmaAccountRecoveryMultisigDeployer,
    '',
    'deploy',
    [[address], 1]
  )

  const DharmaUpgradeBeaconControllerManager = await runTest(
    `DharmaUpgradeBeaconControllerManager contract deployment`,
    DharmaUpgradeBeaconControllerManagerDeployer,
    '',
    'deploy',
    [address]
  )

  const DharmaUpgradeBeaconController = await runTest(
    `DharmaUpgradeBeaconController contract deployment`,
    DharmaUpgradeBeaconControllerDeployer,
    '',
    'deploy',
    [address]
  )

  /*
  const DharmaUpgradeBeaconDeployer = new web3.eth.Contract([])
  DharmaUpgradeBeaconDeployer.options.data = (
    '0x600b5981380380925939f35973' +
    DharmaUpgradeBeaconController.options.address.slice(2).toLowerCase() + 
    '3314602157545952593df35b355955'
  )
  */
  
  const DharmaUpgradeBeacon = await runTest(
    `DharmaUpgradeBeacon contract deployment`,
    DharmaUpgradeBeaconDeployer,
    '',
    'deploy',
    [DharmaUpgradeBeaconController.options.address]
  )

  const DharmaSmartWalletImplementationV0 = await runTest(
    `DharmaSmartWalletImplementationV0 contract deployment`,
    DharmaSmartWalletImplementationV0Deployer,
    '',
    'deploy'
  )

  const DharmaSmartWalletImplementationV1 = await runTest(
    `DharmaSmartWalletImplementationV1 contract deployment`,
    DharmaSmartWalletImplementationV1Deployer,
    '',
    'deploy'
  )

  // TODO: do this the "right" way once everything is working correctly!
  await runTest(
    'Dharma Upgrade Beacon Controller can set initial upgrade beacon implementation',
    DharmaUpgradeBeaconController,
    'upgrade',
    'send',
    [
      DharmaUpgradeBeacon.options.address,
      DharmaSmartWalletImplementationV0.options.address
    ],
    true,
    receipt => {
      if (testingContext !== 'coverage') {
        assert.strictEqual(
          receipt.events.Upgraded.returnValues.upgradeBeacon,
          DharmaUpgradeBeacon.options.address
        )
        assert.strictEqual(
          receipt.events.Upgraded.returnValues.oldImplementation,
          nullAddress
        )
        assert.strictEqual(
          receipt.events.Upgraded.returnValues.oldImplementationCodeHash,
          emptyHash
        )
        assert.strictEqual(
          receipt.events.Upgraded.returnValues.newImplementation,
          DharmaSmartWalletImplementationV0.options.address
        )
        /* TODO
        assert.strictEqual(
          receipt.events.Upgraded.returnValues.newImplementationCodeHash,
          ...
        )
        */
      }
    }
  )

  const UpgradeBeaconImplementationCheck = await runTest(
    `UpgradeBeaconImplementationCheck deployment`,
    UpgradeBeaconImplementationCheckDeployer,
    '',
    'deploy',
    [
      DharmaUpgradeBeacon.options.address,
      DharmaSmartWalletImplementationV0.options.address
    ]
  )

  await runTest(
    'DharmaUpgradeBeacon has the implementation set',
    DharmaUpgradeBeaconController,
    'getImplementation',
    'call',
    [DharmaUpgradeBeacon.options.address],
    true,
    value => {
      assert.strictEqual(value, DharmaSmartWalletImplementationV0.options.address)
    }
  )

  const DharmaSmartWalletNoFactoryNoConstructorDeployer = new web3.eth.Contract([])
  DharmaSmartWalletNoFactoryNoConstructorDeployer.options.data = (
    '0x600b5981380380925939f3595959593659602059595973' +
    DharmaUpgradeBeacon.options.address.slice(2).toLowerCase() + 
    '5afa1551368280375af43d3d93803e603357fd5bf3'
  )

  const DharmaSmartWalletNoFactoryNoConstructor = await runTest(
    `DharmaSmartWallet minimal upgradeable proxy deployment - no factory or constructor`,
    DharmaSmartWalletNoFactoryNoConstructorDeployer,
    '',
    'deploy'
  )

  const DharmaSmartWalletImplementationTest = new web3.eth.Contract(
    DharmaSmartWalletImplementationV0Artifact.abi,
    DharmaSmartWalletNoFactoryNoConstructor.options.address
  )

  await runTest(
    'test passes',
    DharmaSmartWalletImplementationTest,
    'test',
    'call',
    [],
    true,
    value => {
      assert.ok(value)
    }
  )

  const DharmaSmartWalletNoFactoryDeployer = new web3.eth.Contract([])
  DharmaSmartWalletNoFactoryDeployer.options.data = (
    '0x595959596076380359602059595973' +
    DharmaUpgradeBeacon.options.address.slice(2).toLowerCase() +
    '5afa155182607683395af46038573d903d81803efd5b60356041819339f3595959593659602059595973' +
    DharmaUpgradeBeacon.options.address.slice(2).toLowerCase() + 
    '5afa1551368280375af43d3d93803e603357fd5bf3' +
    'c4d66de80000000000000000000000009999999999999999999999999999999999999999'
  )

  const DharmaSmartWalletNoFactory = await runTest(
    `DharmaSmartWallet minimal upgradeable proxy deployment - no factory but with constructor`,
    DharmaSmartWalletNoFactoryDeployer,
    '',
    'deploy'
  )

  const DharmaSmartWalletImplementationTestWithConstructor = new web3.eth.Contract(
    DharmaSmartWalletImplementationV0Artifact.abi,
    DharmaSmartWalletNoFactory.options.address
  )

  await runTest(
    'test passes',
    DharmaSmartWalletImplementationTestWithConstructor,
    'test',
    'call',
    [],
    true,
    value => {
      assert.ok(value)
    }
  )

  await runTest(
    'new user smart wallet can be called and has the correct dharma key set',
    DharmaSmartWalletImplementationTestWithConstructor,
    'getDharmaKey',
    'call',
    [],
    true,
    value => {
      assert.strictEqual(value, '0x9999999999999999999999999999999999999999')
    }
  )

  const DharmaSmartWalletFactoryV1 = await runTest(
    `DharmaSmartWalletFactoryV1 contract deployment`,
    DharmaSmartWalletFactoryV1Deployer,
    '',
    'deploy',
    [DharmaUpgradeBeacon.options.address]
  )

  let targetWalletAddress;
  await runTest(
    'DharmaSmartWalletFactoryV1 can get a new smart wallet address ahead of time',
    DharmaSmartWalletFactoryV1,
    'getNextSmartWallet',
    'call',
    [address],
    true,
    value => {
      // TODO: verify against expected value
      targetWalletAddress = value
    }
  )

  contractNames[DharmaSmartWalletFactoryV1.options.address] = 'Smart Wallet Factory'
  contractNames[targetWalletAddress] = 'Smart Wallet'

  await web3.eth.sendTransaction({
    from: eth_whale,
    to: targetWalletAddress,
    value: web3.utils.toWei('100', 'ether'),
    gas: (testingContext !== 'coverage') ? '0x5208' : gasLimit - 1,
    gasPrice: 1
  })
  console.log(' ✓ Eth Whale can deposit eth into the yet-to-be-deployed smart wallet')

  await runTest(
    'Dai Whale can deposit dai into the yet-to-be-deployed smart wallet',
    DAI,
    'transfer',
    'send',
    [targetWalletAddress, web3.utils.toWei('100', 'ether')],
    true,
    receipt => {
      if (testingContext !== 'coverage') {
        assert.strictEqual(
          receipt.events.Transfer.returnValues.from,
          dai_whale
        )
        assert.strictEqual(
          receipt.events.Transfer.returnValues.to,
          targetWalletAddress
        )
        assert.strictEqual(
          receipt.events.Transfer.returnValues.value,
          web3.utils.toWei('100', 'ether')
        )
      }
    },
    dai_whale
  )

  await runTest(
    'USDC Whale can deposit usdc into the yet-to-be-deployed smart wallet',
    USDC,
    'transfer',
    'send',
    [targetWalletAddress, web3.utils.toWei('100', 'lovelace')], // six decimals
    true,
    receipt => {
      if (testingContext !== 'coverage') {
        assert.strictEqual(
          receipt.events.Transfer.returnValues.from,
          usdc_whale
        )
        assert.strictEqual(
          receipt.events.Transfer.returnValues.to,
          targetWalletAddress
        )
        assert.strictEqual(
          receipt.events.Transfer.returnValues.value,
          web3.utils.toWei('100', 'lovelace')
        )
      }
    },
    usdc_whale
  )

  await runTest(
    'DharmaSmartWalletFactoryV1 can deploy a new smart wallet using a Dharma Key',
    DharmaSmartWalletFactoryV1,
    'newSmartWallet',
    'send',
    [address],
    true,
    receipt => {
      //console.log(receipt.status, receipt.gasUsed)
      if (testingContext !== 'coverage') {
        let events = []
        Object.values(receipt.events).forEach((value) => {
          const log = eventDetails[value.raw.topics[0]]
          const decoded = web3.eth.abi.decodeLog(log.abi, value.raw.data, value.raw.topics)        
          events.push({
            address: contractNames[value.address],
            eventName: log.name,
            returnValues: decoded
          })
        })

        assert.strictEqual(events[0].address, 'Smart Wallet')
        assert.strictEqual(events[0].eventName, 'NewDharmaKey')
        assert.strictEqual(events[0].returnValues.dharmaKey, address)

        assert.strictEqual(events[1].address, 'DAI')
        assert.strictEqual(events[1].eventName, 'Approval')
        assert.strictEqual(events[1].returnValues.value, FULL_APPROVAL)

        assert.strictEqual(events[2].address, 'CDAI')
        assert.strictEqual(events[2].eventName, 'AccrueInterest')

        assert.strictEqual(events[3].address, 'DAI')
        assert.strictEqual(events[3].eventName, 'Transfer')
        assert.strictEqual(events[3].returnValues.value, web3.utils.toWei('100', 'ether'))

        assert.strictEqual(events[4].address, 'CDAI')
        assert.strictEqual(events[4].eventName, 'Mint')
        assert.strictEqual(events[4].returnValues.mintTokens, web3.utils.toWei('100', 'ether'))  

        assert.strictEqual(events[5].address, 'CDAI')
        assert.strictEqual(events[5].eventName, 'Transfer')

        assert.strictEqual(events[6].address, 'USDC')
        assert.strictEqual(events[6].eventName, 'Approval')
        assert.strictEqual(events[6].returnValues.value, FULL_APPROVAL)

        assert.strictEqual(events[7].address, 'CUSDC')
        assert.strictEqual(events[7].eventName, 'AccrueInterest')

        assert.strictEqual(events[8].address, 'USDC')
        assert.strictEqual(events[8].eventName, 'Transfer')
        assert.strictEqual(events[8].returnValues.value, web3.utils.toWei('100', 'lovelace'))

        assert.strictEqual(events[9].address, 'CUSDC')
        assert.strictEqual(events[9].eventName, 'Mint')
        assert.strictEqual(events[9].returnValues.mintTokens, web3.utils.toWei('100', 'lovelace')) 

        assert.strictEqual(events[10].address, 'CUSDC')
        assert.strictEqual(events[10].eventName, 'Transfer')     
      }
    }
  )

  const UserSmartWallet = new web3.eth.Contract(
    DharmaSmartWalletImplementationV0Artifact.abi,
    targetWalletAddress
  )

  await web3.eth.sendTransaction({
    from: eth_whale,
    to: targetWalletAddress,
    value: web3.utils.toWei('100', 'ether'),
    gas: (testingContext !== 'coverage') ? '0xffff' : gasLimit - 1,
    gasPrice: 1
  }).catch(error => {
    console.log(' ✓ Eth Whale can no longer deposit eth into the deployed smart wallet')
  })

  await runTest(
    'Dai Whale can deposit dai into the deployed smart wallet',
    DAI,
    'transfer',
    'send',
    [targetWalletAddress, web3.utils.toWei('100', 'ether')],
    true,
    receipt => {
      if (testingContext !== 'coverage') {
        assert.strictEqual(
          receipt.events.Transfer.returnValues.from,
          dai_whale
        )
        assert.strictEqual(
          receipt.events.Transfer.returnValues.to,
          targetWalletAddress
        )
        assert.strictEqual(
          receipt.events.Transfer.returnValues.value,
          web3.utils.toWei('100', 'ether')
        )
      }
    },
    dai_whale
  )

  await runTest(
    'USDC Whale can deposit usdc into the deployed smart wallet',
    USDC,
    'transfer',
    'send',
    [targetWalletAddress, web3.utils.toWei('100', 'lovelace')], // six decimals
    true,
    receipt => {
      if (testingContext !== 'coverage') {
        assert.strictEqual(
          receipt.events.Transfer.returnValues.from,
          usdc_whale
        )
        assert.strictEqual(
          receipt.events.Transfer.returnValues.to,
          targetWalletAddress
        )
        assert.strictEqual(
          receipt.events.Transfer.returnValues.value,
          web3.utils.toWei('100', 'lovelace')
        )
      }
    },
    usdc_whale
  )

  await runTest(
    'new user smart wallet can trigger repayAndDeposit to deposit all new funds',
    UserSmartWallet,
    'repayAndDeposit',
    'send',
    [],
    true,
    receipt => {
      //console.log(receipt.status, receipt.gasUsed)
      if (testingContext !== 'coverage') {
        let events = []
        Object.values(receipt.events).forEach((value) => {
          const log = eventDetails[value.raw.topics[0]]
          const decoded = web3.eth.abi.decodeLog(log.abi, value.raw.data, value.raw.topics)        
          events.push({
            address: contractNames[value.address],
            eventName: log.name,
            returnValues: decoded
          })
        })
     
        assert.strictEqual(events[0].address, 'CDAI')
        assert.strictEqual(events[0].eventName, 'AccrueInterest')

        assert.strictEqual(events[1].address, 'DAI')
        assert.strictEqual(events[1].eventName, 'Transfer')
        assert.strictEqual(events[1].returnValues.value, web3.utils.toWei('100', 'ether'))

        assert.strictEqual(events[2].address, 'CDAI')
        assert.strictEqual(events[2].eventName, 'Mint')
        assert.strictEqual(events[2].returnValues.mintTokens, web3.utils.toWei('100', 'ether'))

        assert.strictEqual(events[3].address, 'CDAI')
        assert.strictEqual(events[3].eventName, 'Transfer')

        assert.strictEqual(events[4].address, 'CUSDC')
        assert.strictEqual(events[4].eventName, 'AccrueInterest')

        assert.strictEqual(events[5].address, 'USDC')
        assert.strictEqual(events[5].eventName, 'Transfer')
        assert.strictEqual(events[5].returnValues.value, web3.utils.toWei('100', 'lovelace'))

        assert.strictEqual(events[6].address, 'CUSDC')
        assert.strictEqual(events[6].eventName, 'Mint')
        assert.strictEqual(events[6].returnValues.mintTokens, web3.utils.toWei('100', 'lovelace'))

        assert.strictEqual(events[7].address, 'CUSDC')
        assert.strictEqual(events[7].eventName, 'Transfer')
      }
    }
  )

  await runTest(
    'Deployed User Smart Wallet code is correct',
    MockCodeCheck,
    'code',
    'call',
    [UserSmartWallet.options.address],
    true,
    value => {
      assert.strictEqual(value, UpgradeBeaconProxyArtifact.deployedBytecode) 
    }
  )

  await runTest(
    'test passes',
    UserSmartWallet,
    'test',
    'call',
    [],
    true,
    value => {
      assert.ok(value)
    }
  )

  // TODO: wrap in a contract to validate revert reason
  await runTest(
    'revert test with revert reason passes',
    UserSmartWallet,
    'testRevert',
    'call',
    [],
    false // set this to true to verify that the revert reason is displayed
  )

  await runTest(
    'new user smart wallet can be called and has the correct dharma key set',
    UserSmartWallet,
    'getDharmaKey',
    'call',
    [],
    true,
    value => {
      assert.strictEqual(value, address)
    }
  )

  console.log(
    `completed ${passed + failed} test${passed + failed === 1 ? '' : 's'} ` +
    `with ${failed} failure${failed === 1 ? '' : 's'}.`
  )

  if (failed > 0) {
    process.exit(1)
  }

  // exit.
  return 0

}}

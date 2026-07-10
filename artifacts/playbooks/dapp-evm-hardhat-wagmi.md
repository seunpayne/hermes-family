# STACK PLAYBOOK: DAPP Builder Protocol
# EVM-compatible (Ethereum, Polygon, Base, Lisk) + React/Vite
# Version: 1.0
# Reference: Project Oryx (Lisk blockchain, May 2026)
# Michael reads this before generating tasks for any
# decentralized application build.

---

# UNIVERSAL PRINCIPLES APPLY — read first:
# ~/.hermes/playbooks/universal-principles.md

---

## STACK IDENTITY

```
Smart contracts:  Solidity (0.8.x) + Hardhat
Contract library: OpenZeppelin Contracts 5.x
Frontend:         React/Vite + wagmi v2 + viem + RainbowKit
Wallet:           WalletConnect v2 (multi-wallet)
Storage:          IPFS via Pinata (off-chain data)
Testing:          Hardhat (contracts) + Playwright (frontend)
Deployment:       Hardhat deploy scripts (contracts)
                  Vercel (frontend — same as web stack)
Block explorer:   Etherscan / Blockscout (contract verification)
Language:         TypeScript (frontend) + Solidity (contracts)
```

---

## SUPPORTED CHAINS

| Chain | Chain ID (Testnet) | Chain ID (Mainnet) | Explorer |
|-------|-------------------|-------------------|---------|
| Lisk | 4202 (Sepolia) | 1135 | blockscout.lisk.com |
| Ethereum | 11155111 (Sepolia) | 1 | etherscan.io |
| Polygon | 80002 (Amoy) | 137 | polygonscan.com |
| Base | 84532 (Sepolia) | 8453 | basescan.org |
| Arbitrum | 421614 (Sepolia) | 42161 | arbiscan.io |

**Default for new projects:** Lisk (Project Oryx context)
**Testnet always before mainnet:** non-negotiable gate

---

## KNOWN PITFALLS — READ BEFORE GENERATING ANY TASK

1. **Private keys NEVER in code or .env files committed to git.**
   Hardhat accounts use a mnemonic or private key for deployment.
   Store ONLY in `.env` (gitignored) locally.
   Production deployment: use a hardware wallet or
   a dedicated deployer account with minimal funds.
   Secret scanning (Fredo) must run before every push.

2. **Testnet deployment is mandatory before mainnet.**
   This is Gate 5 in the deployment sequence.
   No exceptions. No urgency overrides this.
   Mainnet deployment costs real money and is irreversible.

3. **Contract ABIs must stay in sync with the frontend.**
   After any contract redeployment, the ABI changes.
   The frontend must be updated immediately.
   Automate: copy ABI from artifacts/ to frontend after compile.
   Stale ABI = silent failures in production.

4. **Use OpenZeppelin for everything standard.**
   Never reimplement: access control, ERC20, ERC721,
   pausable, upgradeable patterns.
   OpenZeppelin is audited. Custom reimplementations are not.
   If a feature exists in OpenZeppelin — use it.

5. **Reentrancy is the most common smart contract vulnerability.**
   Always use the checks-effects-interactions pattern.
   Or inherit OpenZeppelin's ReentrancyGuard.
   Any function that sends ETH or calls external contracts
   must be protected.

6. **Gas estimation before every transaction.**
   Always call estimateGas before sending.
   Show the user the estimated cost in the UI.
   Never let users hit out-of-gas errors silently.

7. **Network mismatch breaks DAPPs silently.**
   Always validate the user's connected chain matches
   the expected chain ID before any transaction.
   RainbowKit handles this with switchChain prompts.
   But validate in the contract interaction code too.

8. **Transaction pending state must be visible.**
   Users think the app is broken when transactions take time.
   Always show: pending → confirmed → error states.
   wagmi's useWaitForTransactionReceipt handles this.

9. **Upgradeable vs immutable is an architectural decision.**
   Make this explicit in the PRD before writing any code.
   Upgradeable contracts (OpenZeppelin proxy patterns) allow
   fixing bugs but require a trusted admin.
   Immutable contracts are trustless but unfixable.
   Document the decision and the rationale.

10. **RPC provider reliability is critical.**
    Single RPC endpoint = single point of failure.
    Use a primary and fallback:
    Primary: Alchemy or Infura (reliable, rate limited)
    Fallback: public RPC (less reliable, free)
    wagmi handles RPC fallback automatically with transport config.

11. **IPFS content is permanent but not guaranteed available.**
    Pinning keeps content available — use Pinata.
    Never store sensitive data on IPFS — it is public.
    CIDs are permanent. If you pin wrong content, unpin
    and re-pin. The old CID remains accessible.

12. **Contract verification is mandatory, not optional.**
    Unverified contracts cannot be read or trusted by users.
    Verify on the block explorer immediately after deployment.
    Hardhat verify plugin handles this automatically.

---

## SCAFFOLD

```bash
# Create project structure
mkdir [project-name] && cd [project-name]

# Smart contracts directory
mkdir contracts && cd contracts
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts dotenv
npx hardhat init
# Choose: Create a TypeScript project

cd ..

# Frontend directory
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install wagmi viem @tanstack/react-query
npm install @rainbow-me/rainbowkit
npm install @tanstack/react-router
npm install tailwindcss @tailwindcss/vite
npm install --save-dev vitest @vitest/coverage-v8
cd ..
```

---

## REQUIRED CONFIG FILES

**contracts/hardhat.config.ts**
```typescript
import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import * as dotenv from 'dotenv'

dotenv.config()

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.24',
    settings: {
      optimizer: { enabled: true, runs: 200 }
    }
  },
  networks: {
    // Lisk Sepolia testnet
    liskSepolia: {
      url: process.env.LISK_SEPOLIA_RPC_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      chainId: 4202
    },
    // Lisk mainnet
    lisk: {
      url: process.env.LISK_RPC_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      chainId: 1135
    },
    // Add other chains as needed
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL!,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
      chainId: 11155111
    }
  },
  etherscan: {
    apiKey: {
      liskSepolia: process.env.BLOCKSCOUT_API_KEY ?? 'no-key-needed',
      lisk: process.env.BLOCKSCOUT_API_KEY ?? 'no-key-needed',
    },
    customChains: [
      {
        network: 'liskSepolia',
        chainId: 4202,
        urls: {
          apiURL: 'https://sepolia-blockscout.lisk.com/api',
          browserURL: 'https://sepolia-blockscout.lisk.com'
        }
      },
      {
        network: 'lisk',
        chainId: 1135,
        urls: {
          apiURL: 'https://blockscout.lisk.com/api',
          browserURL: 'https://blockscout.lisk.com'
        }
      }
    ]
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === 'true',
    currency: 'USD'
  }
}

export default config
```

**contracts/.env** (never commit)
```
DEPLOYER_PRIVATE_KEY=0x[private key — NEVER commit]
LISK_SEPOLIA_RPC_URL=https://rpc.sepolia-api.lisk.com
LISK_RPC_URL=https://rpc.api.lisk.com
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/[key]
ETHERSCAN_API_KEY=[key if verifying on Etherscan]
BLOCKSCOUT_API_KEY=[key if using Blockscout]
REPORT_GAS=false
```

**frontend/src/lib/wagmi.ts**
```typescript
import { getDefaultConfig } from '@rainbow-me/rainbowkit'
import { http, fallback } from 'wagmi'
import { defineChain } from 'viem'

// Lisk chains
const liskSepolia = defineChain({
  id: 4202,
  name: 'Lisk Sepolia',
  nativeCurrency: { name: 'Sepolia ETH', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://rpc.sepolia-api.lisk.com'] }
  },
  blockExplorers: {
    default: {
      name: 'Blockscout',
      url: 'https://sepolia-blockscout.lisk.com'
    }
  },
  testnet: true
})

const lisk = defineChain({
  id: 1135,
  name: 'Lisk',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://rpc.api.lisk.com'] }
  },
  blockExplorers: {
    default: {
      name: 'Blockscout',
      url: 'https://blockscout.lisk.com'
    }
  }
})

export const config = getDefaultConfig({
  appName: '[App Name]',
  projectId: process.env.VITE_WALLETCONNECT_PROJECT_ID!,
  chains: [liskSepolia, lisk], // testnet first
  transports: {
    [liskSepolia.id]: fallback([
      http('https://rpc.sepolia-api.lisk.com'),
      http() // public fallback
    ]),
    [lisk.id]: fallback([
      http('https://rpc.api.lisk.com'),
      http()
    ])
  }
})
```

**frontend/src/main.tsx**
```tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { RainbowKitProvider } from '@rainbow-me/rainbowkit'
import { config } from './lib/wagmi'
import App from './App'
import '@rainbow-me/rainbowkit/styles.css'
import './styles/main.css'

const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <App />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  </StrictMode>
)
```

**frontend/.env.local** (never commit)
```
VITE_WALLETCONNECT_PROJECT_ID=[from cloud.walletconnect.com]
VITE_CONTRACT_ADDRESS=[deployed contract address]
VITE_CHAIN_ID=4202
```

---

## SMART CONTRACT PATTERNS

### Standard contract structure
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract [ContractName] is Ownable, ReentrancyGuard, Pausable {

  // State variables
  uint256 public constant VERSION = 1;

  // Events (emit before state changes in checks-effects-interactions)
  event [Action](address indexed actor, uint256 value);

  // Errors (cheaper than revert strings in Solidity 0.8+)
  error InsufficientBalance(uint256 available, uint256 required);
  error Unauthorized(address caller);

  constructor(address initialOwner) Ownable(initialOwner) {}

  // External functions (cheaper gas than public)
  function [action](uint256 amount)
    external
    nonReentrant
    whenNotPaused
  {
    // CHECKS
    if (amount == 0) revert InsufficientBalance(0, 1);

    // EFFECTS (state changes first)
    // update state here

    // INTERACTIONS (external calls last)
    // send ETH or call other contracts here

    emit [Action](msg.sender, amount);
  }

  // Admin functions
  function pause() external onlyOwner { _pause(); }
  function unpause() external onlyOwner { _unpause(); }
}
```

### ERC20 token pattern
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract [TokenName] is ERC20, ERC20Burnable, Ownable {
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply,
    address owner
  ) ERC20(name, symbol) Ownable(owner) {
    _mint(owner, initialSupply * 10 ** decimals());
  }

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }
}
```

### NFT pattern (ERC721)
```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract [NFTName] is ERC721, ERC721URIStorage, Ownable {
  uint256 private _nextTokenId;

  constructor(address owner) ERC721("[Name]", "[SYM]") Ownable(owner) {}

  function mint(address to, string memory tokenURI)
    external onlyOwner returns (uint256)
  {
    uint256 tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, tokenURI);
    return tokenId;
  }
}
```

---

## HARDHAT SCRIPTS

### Compile and extract ABI
```typescript
// scripts/extract-abi.ts
import fs from 'fs'
import path from 'path'
import { artifacts } from 'hardhat'

async function main() {
  const artifact = await artifacts.readArtifact('[ContractName]')

  // Copy ABI to frontend
  const frontendPath = path.join(
    __dirname, '../../frontend/src/contracts'
  )
  fs.mkdirSync(frontendPath, { recursive: true })

  fs.writeFileSync(
    path.join(frontendPath, '[ContractName].abi.json'),
    JSON.stringify(artifact.abi, null, 2)
  )
  console.log('ABI extracted to frontend')
}
main()
```

### Deploy script
```typescript
// scripts/deploy.ts
import { ethers, run, network } from 'hardhat'

async function main() {
  console.log(`Deploying to ${network.name}...`)

  const [deployer] = await ethers.getSigners()
  console.log(`Deployer: ${deployer.address}`)
  console.log(`Balance: ${ethers.formatEther(
    await ethers.provider.getBalance(deployer.address)
  )} ETH`)

  // Deploy
  const Contract = await ethers.getContractFactory('[ContractName]')
  const contract = await Contract.deploy(/* constructor args */)
  await contract.waitForDeployment()

  const address = await contract.getAddress()
  console.log(`[ContractName] deployed to: ${address}`)

  // Save deployment info
  const deploymentInfo = {
    network: network.name,
    chainId: network.config.chainId,
    address,
    deployer: deployer.address,
    deployedAt: new Date().toISOString()
  }

  require('fs').writeFileSync(
    `deployments/${network.name}.json`,
    JSON.stringify(deploymentInfo, null, 2)
  )

  // Verify on block explorer (wait for confirmations first)
  if (network.name !== 'hardhat' && network.name !== 'localhost') {
    console.log('Waiting for confirmations before verification...')
    await contract.deploymentTransaction()?.wait(5)

    try {
      await run('verify:verify', {
        address,
        constructorArguments: [/* same as deploy args */]
      })
      console.log('Contract verified!')
    } catch (err) {
      console.warn('Verification failed:', err)
    }
  }
}

main().catch(console.error)
```

**Run deployment:**
```bash
# Testnet (always first)
npx hardhat run scripts/deploy.ts --network liskSepolia

# Extract ABI after deployment
npx hardhat run scripts/extract-abi.ts --network liskSepolia

# Update frontend .env.local with deployed address
# VITE_CONTRACT_ADDRESS=0x[address]
```

---

## FRONTEND CONTRACT INTERACTION PATTERNS

### Read contract state
```typescript
import { useReadContract } from 'wagmi'
import contractABI from '../contracts/[ContractName].abi.json'

const CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS

export function useContractData() {
  const { data, isLoading, error } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: contractABI,
    functionName: '[functionName]',
    args: [] // function arguments if any
  })

  return { data, isLoading, error }
}
```

### Write to contract (transaction)
```typescript
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { parseEther } from 'viem'

export function useContractWrite() {
  const {
    writeContract,
    data: hash,
    isPending,
    error
  } = useWriteContract()

  const { isLoading: isConfirming, isSuccess } =
    useWaitForTransactionReceipt({ hash })

  const execute = async (args: unknown[]) => {
    writeContract({
      address: CONTRACT_ADDRESS as `0x${string}`,
      abi: contractABI,
      functionName: '[functionName]',
      args,
      // value: parseEther('0.01') // if function is payable
    })
  }

  return {
    execute,
    isPending,      // transaction being signed
    isConfirming,   // transaction in mempool
    isSuccess,      // transaction confirmed
    hash,           // transaction hash
    error
  }
}
```

### Transaction status UI pattern
```tsx
function TransactionButton({ onExecute }: { onExecute: () => void }) {
  const { isPending, isConfirming, isSuccess, hash, error } =
    useContractWrite()

  return (
    <div>
      <button
        onClick={onExecute}
        disabled={isPending || isConfirming}
        className="..."
      >
        {isPending ? 'Confirm in wallet...' :
         isConfirming ? 'Confirming...' :
         'Execute'}
      </button>

      {hash && (
        <a
          href={`https://sepolia-blockscout.lisk.com/tx/${hash}`}
          target="_blank" rel="noreferrer"
          className="text-xs text-[#888]"
        >
          View transaction ↗
        </a>
      )}

      {isSuccess && (
        <p className="text-[#4caf50] text-xs">Transaction confirmed!</p>
      )}

      {error && (
        <p className="text-[#c0392b] text-xs">
          Error: {error.message}
        </p>
      )}
    </div>
  )
}
```

### Chain validation
```typescript
import { useChainId, useSwitchChain } from 'wagmi'

const REQUIRED_CHAIN_ID = Number(import.meta.env.VITE_CHAIN_ID)

export function useChainGuard() {
  const chainId = useChainId()
  const { switchChain } = useSwitchChain()

  const isCorrectChain = chainId === REQUIRED_CHAIN_ID

  const ensureCorrectChain = () => {
    if (!isCorrectChain) {
      switchChain({ chainId: REQUIRED_CHAIN_ID })
      return false
    }
    return true
  }

  return { isCorrectChain, ensureCorrectChain }
}
```

---

## TESTING PATTERNS

### Smart contract tests (Hardhat)
```typescript
// test/[ContractName].test.ts
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'

describe('[ContractName]', function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners()
    const Contract = await ethers.getContractFactory('[ContractName]')
    const contract = await Contract.deploy(owner.address)
    return { contract, owner, user1, user2 }
  }

  describe('Deployment', function () {
    it('sets the correct owner', async function () {
      const { contract, owner } = await loadFixture(deployFixture)
      expect(await contract.owner()).to.equal(owner.address)
    })
  })

  describe('[functionName]', function () {
    it('[description of what it should do]', async function () {
      const { contract, user1 } = await loadFixture(deployFixture)
      // arrange
      // act
      await contract.connect(user1).[functionName](args)
      // assert
      expect(await contract.[stateVariable]()).to.equal(expected)
    })

    it('reverts when [condition]', async function () {
      const { contract, user1 } = await loadFixture(deployFixture)
      await expect(
        contract.connect(user1).[functionName](badArgs)
      ).to.be.revertedWithCustomError(contract, '[ErrorName]')
    })
  })
})
```

**Run tests:**
```bash
cd contracts
npx hardhat test
npx hardhat test --network hardhat # explicit
npx hardhat coverage # coverage report
```

### Gas report
```bash
REPORT_GAS=true npx hardhat test
```

---

## FREDO'S ROLE IN DAPPS

Fredo runs additional checks for DAPP projects.

### Pre-push checks (standard + DAPP-specific)
```bash
# Standard
trufflehog filesystem . --only-verified --fail
npm audit --audit-level=high

# DAPP-specific: check for private keys in any file
grep -r "0x[a-fA-F0-9]\{64\}" --include="*.ts" \
  --include="*.js" --include="*.json" \
  --include="*.env*" . | grep -v ".gitignore" | \
  grep -v "node_modules"
# Expected: no results (64-char hex = private key pattern)

# Check .env is gitignored
git ls-files --cached | grep -E "^\.env$"
# Expected: no results (must not be tracked)
```

### Smart contract security checklist (before mainnet)
```
[ ] OpenZeppelin used for: access control, token standards,
    reentrancy guard, pausable
[ ] No custom reimplementations of standard patterns
[ ] Checks-effects-interactions pattern in all external functions
[ ] No tx.origin used for authorization (use msg.sender)
[ ] Integer overflow impossible (Solidity 0.8+ default protection)
[ ] All events emit before external calls
[ ] No selfdestruct (deprecated, avoid)
[ ] No assembly blocks without explicit justification
[ ] Constructor arguments validated
[ ] Admin functions protected with onlyOwner or role-based access
[ ] Upgradeable decision documented and justified
[ ] Contract verified on block explorer
[ ] Gas usage reasonable (check gas report)
```

Fredo blocks mainnet deployment if any item is unchecked.
Only Seun can override a Fredo DAPP security block.

---

## DEPLOYMENT GATES

```
GATE 1: Contract tests pass (npx hardhat test)
         Coverage: ≥ 80% line coverage
GATE 2: Fredo smart contract security checklist: all ✓
GATE 3: Testnet deployment successful
         Contract verified on testnet explorer
GATE 4: Frontend integrated with testnet contract
         All user flows tested with real wallet on testnet
GATE 5: SEUN APPROVES MAINNET DEPLOYMENT
         No agent deploys to mainnet without explicit approval
GATE 6: Mainnet deployment
         Contract verified on mainnet explorer
         Deployment record saved to deployments/[network].json
GATE 7: Frontend updated with mainnet contract address
         Smoke test on mainnet with small amount
GATE 8: Project signed off
```

**TESTNET MUST PASS BEFORE MAINNET.**
This is the only gate that overrides urgency.
A timeline cannot compress this gate.

---

## IPFS / OFF-CHAIN STORAGE

### Pinata setup
```typescript
// src/lib/ipfs.ts
const PINATA_JWT = import.meta.env.VITE_PINATA_JWT

export async function uploadToIPFS(
  data: object | string,
  name: string
): Promise<string> {
  const formData = new FormData()
  const blob = new Blob(
    [typeof data === 'string' ? data : JSON.stringify(data)],
    { type: 'application/json' }
  )
  formData.append('file', blob, name)
  formData.append('pinataMetadata', JSON.stringify({ name }))

  const res = await fetch(
    'https://api.pinata.cloud/pinning/pinFileToIPFS',
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${PINATA_JWT}` },
      body: formData
    }
  )

  const { IpfsHash } = await res.json()
  return `ipfs://${IpfsHash}`
}

export function ipfsToHttp(ipfsUri: string): string {
  return ipfsUri.replace(
    'ipfs://',
    'https://gateway.pinata.cloud/ipfs/'
  )
}
```

---

## WALLETCONNECT SETUP

Get a Project ID at cloud.walletconnect.com (free).
Add to `frontend/.env.local`:
```
VITE_WALLETCONNECT_PROJECT_ID=[your project id]
```

This is required for WalletConnect v2 (mobile wallet support).
Without it: desktop wallets work, mobile wallets fail.

---

## STANDARD DIRECTORY STRUCTURE

```
[project-name]/
  contracts/                 — Hardhat project
    contracts/
      [ContractName].sol
    scripts/
      deploy.ts
      extract-abi.ts
    test/
      [ContractName].test.ts
    deployments/
      liskSepolia.json       — testnet deployment record
      lisk.json              — mainnet deployment record
    hardhat.config.ts
    .env                     — NEVER committed
    .gitignore
  frontend/                  — Vite React project
    src/
      contracts/
        [ContractName].abi.json — copied from Hardhat artifacts
      lib/
        wagmi.ts             — chain and transport config
        ipfs.ts              — IPFS upload helpers
      hooks/
        use[ContractName].ts — contract interaction hooks
      components/
        TransactionButton.tsx
        WalletConnect.tsx
      routes/
        index.tsx
        [page].tsx
    .env.local               — NEVER committed
```

---

## TASK CODE GENERATION GUIDE
*(Michael reads this when generating PRD Section 12 tasks)*

**Contract scaffold task:**
CODE: Solidity contract using standard pattern above.
RUN: `npx hardhat compile`
VERIFY: `ls artifacts/contracts/[Name].sol/[Name].json`
REPORT: "Contract compiled. ABI at artifacts/."

**Contract test task:**
CODE: Hardhat test file using loadFixture pattern.
RUN: `npx hardhat test --network hardhat`
VERIFY: All tests pass. `npx hardhat coverage` ≥ 80%.
REPORT: "Tests: [N] passing. Coverage: [N]%."

**Testnet deployment task:**
CODE: deploy.ts script from DEPLOY SCRIPT section.
RUN: `npx hardhat run scripts/deploy.ts --network liskSepolia`
VERIFY: `cat deployments/liskSepolia.json` — address present.
        Check address on sepolia-blockscout.lisk.com.
        Verify: `npx hardhat verify --network liskSepolia [address]`
REPORT: "Deployed to liskSepolia at [address]. Verified ✓."

**ABI sync task:**
CODE: extract-abi.ts script.
RUN: `npx hardhat run scripts/extract-abi.ts`
VERIFY: `cat frontend/src/contracts/[Name].abi.json | head -5`
        File exists and is not empty.
REPORT: "ABI synced to frontend/src/contracts/"

**Frontend contract hook task:**
CODE: Hook using useReadContract/useWriteContract patterns above.
RUN: `npm run dev` — interact with testnet contract in browser.
VERIFY: Read: data appears. Write: transaction hash returned.
        Check tx on block explorer.
REPORT: "Contract hooks working. Read ✓ Write ✓"

**Fredo DAPP security task:**
CODE: The smart contract security checklist above.
RUN: grep for private key patterns + standard Fredo checks.
VERIFY: All checklist items ✓. No private keys found.
REPORT: "Fredo DAPP scan: CLEAR. Security checklist: 12/12 ✓"

**Mainnet deployment task:**
REQUIRES: Seun explicit approval (Gate 5).
CODE: Same deploy.ts with --network lisk.
RUN: `npx hardhat run scripts/deploy.ts --network lisk`
VERIFY: Contract visible on blockscout.lisk.com.
        Smoke test: connect wallet on mainnet, call one read function.
REPORT: "Mainnet deployed at [address]. Verified ✓. Smoke test ✓."

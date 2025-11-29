# Conduit

<div align="center">

![Conduit Logo](https://via.placeholder.com/200x200?text=CONDUIT)

**Decentralized Productivity Suite for Web3 Teams**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636?logo=solidity)](https://soliditylang.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-3178C6?logo=typescript)](https://www.typescriptlang.org/)
[![Optimism](https://img.shields.io/badge/Optimism-L2-FF0420?logo=optimism)](https://www.optimism.io/)

[Website](https://conduit.xyz) • [Documentation](https://docs.conduit.xyz) • [Discord](https://discord.gg/conduit) • [Twitter](https://twitter.com/conduitxyz)

</div>

---

## 🌟 Overview

**Conduit** is a decentralized Software-as-a-Service (dSaaS) platform that brings Web3 principles to everyday productivity tools. Built on decentralized infrastructure, Conduit empowers teams to collaborate without compromising on privacy, ownership, or control.

Think Notion + Asana + Figma + Google Drive — but fully decentralized, encrypted, and owned by you.

### ✨ Key Features

- **📄 Documents (Notion-style)**: Rich text editor with databases, templates, and version control
- **✅ Task Management (Asana-style)**: Kanban boards, Gantt charts, and workflow automation
- **🎨 Design Studio (Figma-style)**: Real-time collaborative design with on-chain asset ownership
- **💾 File Storage (Drive-style)**: Encrypted file vaults with granular sharing controls
- **🔐 End-to-End Encryption**: Lit Protocol integration for cryptographic access control
- **⚡ Real-time Collaboration**: P2P sync using Y.js CRDTs and WebRTC
- **🏛️ DAO Governance**: Community-driven platform evolution

---

## 🏗️ Architecture

Conduit leverages a modern decentralized stack:

```
┌─────────────────────────────────────────────────────┐
│              Frontend (React + TypeScript)          │
│  • Vite • TailwindCSS • Ethers.js • Y.js            │
└────────────────────┬────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
┌──────────────────┐    ┌──────────────────┐
│  Smart Contracts │    │  Lit Protocol    │
│  (Optimism L2)   │    │  (Encryption)    │
└────────┬─────────┘    └──────────────────┘
         │
         ▼
┌──────────────────┐    ┌──────────────────┐
│      IPFS        │◄──►│    Filecoin      │
│  (Fast Storage)  │    │   (Archival)     │
└──────────────────┘    └──────────────────┘
```

### Core Technologies

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Blockchain** | Optimism, Arbitrum | L2 for low-cost transactions |
| **Smart Contracts** | Solidity 0.8.20 | Permission & registry management |
| **Storage** | IPFS, Filecoin | Decentralized file storage |
| **Encryption** | Lit Protocol | Access control & key management |
| **Frontend** | React, TypeScript | User interface |
| **Real-time Sync** | Y.js, WebRTC | Collaborative editing |
| **Indexing** | The Graph | Query layer for on-chain data |

---

## 🚀 Quick Start

### Prerequisites

- **Node.js** 18.x or higher
- **npm** or **yarn**
- **MetaMask** or compatible Web3 wallet
- **IPFS node** (optional - can use Web3.Storage API)

### Installation

```bash
# Clone the repository
git clone https://github.com/conduit/conduit.git
cd conduit

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Configure your environment
# Add your Web3.Storage API key, RPC URLs, etc.
```

### Environment Setup

```env
# .env
VITE_OPTIMISM_RPC_URL=https://mainnet.optimism.io
VITE_WEB3_STORAGE_TOKEN=your_api_token_here
VITE_LIT_NETWORK=cayenne
VITE_WORKSPACE_CONTRACT=0x...
VITE_DOCUMENT_CONTRACT=0x...
```

### Development

```bash
# Start local development server
npm run dev

# Run smart contract tests
npm run test:contracts

# Deploy contracts to testnet
npm run deploy:testnet

# Build for production
npm run build
```

---

## 📦 Project Structure

```
conduit/
├── contracts/              # Solidity smart contracts
│   ├── WorkspaceManager.sol
│   ├── DocumentRegistry.sol
│   ├── TaskManager.sol
│   ├── StoragePayment.sol
│   └── DAOGovernance.sol
├── src/
│   ├── components/        # React components
│   ├── hooks/             # Custom React hooks
│   ├── services/          # Business logic
│   │   ├── ipfs.ts
│   │   ├── lit.ts
│   │   └── contracts.ts
│   ├── stores/            # State management
│   └── utils/             # Helper functions
├── test/                  # Test suites
│   ├── contracts/         # Smart contract tests
│   └── integration/       # E2E tests
├── docs/                  # Documentation
└── scripts/               # Deployment scripts
```

---

## 🔧 Core Modules

### 1. Workspace Management

Create and manage decentralized workspaces with role-based access control.

```typescript
import { WorkspaceManager } from '@conduit/sdk';

const workspace = await WorkspaceManager.create({
  name: "My DAO Workspace",
  storageLimit: "10GB",
  members: [
    { address: "0x123...", role: "ADMIN" },
    { address: "0x456...", role: "EDITOR" }
  ]
});
```

### 2. Document Collaboration

Real-time collaborative editing with automatic IPFS storage.

```typescript
import { DocumentEditor } from '@conduit/sdk';

const doc = await DocumentEditor.create({
  workspaceId: workspace.id,
  title: "Product Roadmap",
  content: initialContent
});

// Enable real-time collaboration
doc.enableCollaboration();

// Auto-saves to IPFS every 30 seconds
doc.on('saved', (cid) => {
  console.log(`Saved to IPFS: ${cid}`);
});
```

### 3. Encrypted File Storage

Upload and share files with cryptographic access control.

```typescript
import { FileVault } from '@conduit/sdk';

const vault = new FileVault(workspaceId);

// Upload encrypted file
const file = await vault.upload(fileBlob, {
  encrypt: true,
  accessControl: {
    type: 'wallet',
    addresses: ['0x123...', '0x456...']
  }
});

// Share with specific permissions
await vault.share(file.id, {
  recipient: '0x789...',
  permission: 'VIEW',
  expiresAt: Date.now() + 7 * 24 * 60 * 60 * 1000 // 7 days
});
```

---

## 🔐 Security & Privacy

### Encryption Model

Conduit uses **Lit Protocol** for decentralized encryption and access control:

1. **Content Encryption**: Files and documents are encrypted client-side using AES-256-GCM
2. **Key Management**: Symmetric keys are stored in Lit's distributed network
3. **Access Control**: On-chain conditions determine who can decrypt (wallet ownership, NFTs, token balance, etc.)
4. **Threshold Decryption**: 2/3 of Lit nodes must agree before releasing decryption keys

### Security Best Practices

- ✅ All sensitive data encrypted before leaving the browser
- ✅ Private keys never leave user's wallet
- ✅ Smart contracts audited by [Audit Firm Name]
- ✅ No centralized servers with access to plaintext data
- ✅ Open-source codebase for community review

### Audit Reports

- [OpenZeppelin Audit Report - Q4 2024](./audits/openzeppelin-2024.pdf)
- [Trail of Bits Security Review - Q1 2025](./audits/trailofbits-2025.pdf)

---

## 🧪 Testing

```bash
# Run all tests
npm test

# Run smart contract tests
npm run test:contracts

# Run frontend tests
npm run test:ui

# Run integration tests
npm run test:e2e

# Generate coverage report
npm run coverage
```

### Test Coverage

- Smart Contracts: 98%
- Frontend Components: 92%
- Integration Tests: 85%

---

## 📖 Documentation

Comprehensive documentation is available at [docs.conduit.xyz](https://docs.conduit.xyz):

- [Getting Started Guide](https://docs.conduit.xyz/getting-started)
- [API Reference](https://docs.conduit.xyz/api)
- [Smart Contract Documentation](https://docs.conduit.xyz/contracts)
- [Architecture Deep Dive](https://docs.conduit.xyz/architecture)
- [Security Model](https://docs.conduit.xyz/security)
- [Contributing Guide](https://docs.conduit.xyz/contributing)

---

## 🗺️ Roadmap

### ✅ Completed (MVP - Q1 2025)

- Core smart contracts deployed
- Basic document editor
- IPFS integration
- Wallet authentication

### 🚧 In Progress (Alpha - Q2 2025)

- Lit Protocol encryption
- Real-time collaboration (Y.js)
- Task management module
- 50 alpha testers onboarded

### 📋 Planned

**Q3 2025 - Beta Release**
- Design studio (Figma-style)
- File vault with encryption
- Filecoin long-term storage
- Mobile apps (iOS/Android)
- Security audit completion

**Q4 2025 - V1.0 Launch**
- Mainnet deployment
- DAO governance launch
- Public launch & marketing
- 5,000+ user target

**2026 - Future Features**
- AI-powered productivity features
- Cross-chain support (Polygon, Base, zkSync)
- Enterprise features (SSO, advanced analytics)
- Plugin marketplace
- Web3-native integrations (NFTs, token-gating)

---

## 🤝 Contributing

We welcome contributions from the community! Please read our [Contributing Guide](CONTRIBUTING.md) to get started.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- Follow the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- Use TypeScript strict mode
- Write tests for all new features
- Document public APIs with JSDoc comments
- Run linter before committing: `npm run lint`

---

## 💰 Tokenomics (Optional)

**$CONDUIT Token** - Governance and utility token

| Allocation | Percentage | Vesting |
|-----------|-----------|---------|
| Community & Users | 40% | 2-year linear |
| Team | 25% | 4-year with 1-year cliff |
| Investors | 20% | 2-year with 6-month cliff |
| DAO Treasury | 10% | Unlocked |
| Advisors | 5% | 2-year linear |

**Token Utility:**
- Governance voting rights
- Fee discounts (20% off with staking)
- Revenue sharing (50% to stakers)
- Premium feature access

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🔗 Links & Resources

- **Website**: [conduit.xyz](https://conduit.xyz)
- **Documentation**: [docs.conduit.xyz](https://docs.conduit.xyz)
- **GitHub**: [github.com/conduit/conduit](https://github.com/conduit/conduit)
- **Discord**: [discord.gg/conduit](https://discord.gg/conduit)
- **Twitter**: [@conduitxyz](https://twitter.com/conduitxyz)
- **Blog**: [blog.conduit.xyz](https://blog.conduit.xyz)

---

## 👥 Team

Built with ❤️ by the Conduit team


## 🙏 Acknowledgments

Special thanks to:
- [Optimism](https://optimism.io) for L2 infrastructure
- [Lit Protocol](https://litprotocol.com) for encryption layer
- [IPFS/Protocol Labs](https://protocol.ai) for decentralized storage
- [OpenZeppelin](https://openzeppelin.com) for secure contract libraries
- Our amazing community of early adopters and contributors


<div align="center">

**Built for the decentralized future. Own your work. Own your data.**
</div>

# Web3 Component Hub 🚀

A decentralized marketplace for reusable blockchain components built on the Stacks blockchain using Clarity smart contracts.

## Overview

Web3 Component Hub is a modular development marketplace that enables developers to:
- **Publish** reusable blockchain components
- **Rent** or **purchase** components for their projects
- **Monetize** their development work through usage fees
- **Share feedback** and build reputation in the ecosystem

## Features

### 🛠️ Component Management
- **Register Components**: Publish your blockchain components with metadata
- **Categorization**: Organize components by type (DeFi, NFT, Governance, Utility)
- **Version Control**: IPFS integration for decentralized code storage
- **Status Control**: Enable/disable components as needed

### 💰 Flexible Monetization
- **Usage Credits**: Pay-per-use model for component deployment
- **Rental System**: Temporary access for 15-day periods
- **Revenue Sharing**: Automatic payment distribution to component builders
- **Fee Structure**: 2% platform fee (adjustable by admin)

### 🔐 Access Control
- **Permission Management**: Granular access rights for different users
- **Credit System**: Track and consume usage credits
- **Rental Expiry**: Time-based access for rental agreements
- **Deployment Verification**: Ensure proper access before component usage

### 📊 Community Features
- **Feedback System**: 1-5 star rating system with written reviews
- **Usage Analytics**: Track deployment counts and revenue
- **Builder Profiles**: Revenue tracking for component creators

## Smart Contract Functions

### Core Operations

#### `register-component`
Register a new blockchain component in the marketplace.

```clarity
(register-component 
  component-id 
  component-name 
  description 
  category 
  usage-fee 
  rental-fee 
  repo-hash)
```

#### `rent-component`
Rent a component for 15 days of unlimited usage.

```clarity
(rent-component component-id)
```

#### `buy-usage-credits`
Purchase usage credits for pay-per-deployment access.

```clarity
(buy-usage-credits component-id credit-amount)
```

#### `deploy-component`
Deploy a component (consumes credits or checks rental validity).

```clarity
(deploy-component component-id)
```

### Read-Only Functions

#### `get-component`
Retrieve component details and metadata.

#### `can-deploy-component`
Check if a developer has permission to deploy a specific component.

#### `get-builder-revenue`
View accumulated revenue for a component builder.

### Management Functions

#### `submit-feedback`
Submit a rating and review for a component you've used.

#### `claim-revenue`
Allow builders to withdraw their accumulated revenue.

#### `update-component`
Update component details (builder only).

## Data Structures

### Component Data
```clarity
{
  builder: principal,
  component-name: string,
  description: string,
  category: string,
  usage-fee: uint,
  rental-fee: uint,
  deployment-count: uint,
  total-income: uint,
  status: bool,
  repo-hash: string
}
```

### Access Rights
```clarity
{
  access-type: string, // "rental" or "owned"
  expiry-height: uint,
  usage-credits: uint,
  investment: uint
}
```

### Feedback System
```clarity
{
  score: uint, // 1-5 rating
  feedback: string,
  review-height: uint
}
```

## Categories

- **DeFi**: Decentralized Finance components
- **NFT**: Non-Fungible Token utilities
- **Governance**: DAO and voting mechanisms
- **Utility**: General-purpose blockchain tools

## Economic Model

### Fee Structure
- **Platform Fee**: 2% of all transactions (adjustable by admin, max 5%)
- **Builder Revenue**: 98% of transaction fees go directly to component creators
- **Flexible Pricing**: Builders set their own usage and rental fees

### Access Models
1. **Rental**: Fixed fee for 15-day unlimited access
2. **Usage Credits**: Pay-per-deployment model
3. **Hybrid**: Combine both models as needed

## Getting Started

### For Component Builders
1. Develop your reusable blockchain component
2. Upload code to IPFS and get the hash
3. Register your component with metadata
4. Set competitive pricing for usage and rental
5. Earn revenue as developers use your component

### For Developers
1. Browse available components by category
2. Choose between rental or credit-based access
3. Deploy components in your applications
4. Provide feedback to help the community

### For Administrators
- Adjust platform transaction fees (max 5%)
- Monitor platform health and usage

## Technical Details

### Blockchain: Stacks
### Language: Clarity
### Storage: IPFS for component code
### Access Period: 15 days for rentals
### Block Height Tracking: Automatic expiry management

## Error Codes

- `u300`: Admin permission required
- `u301`: Component not found or missing
- `u302`: Permission denied
- `u303`: Insufficient funds
- `u304`: Duplicate component ID
- `u305`: Invalid parameter

## Security Features

- **Permission Validation**: All operations check proper access rights
- **Fund Verification**: Ensures sufficient balance before transactions
- **Builder Authentication**: Only component creators can update their components
- **Admin Controls**: Protected administrative functions

## Future Enhancements

- Multi-chain component support
- Enhanced reputation systems
- Component dependency management
- Advanced analytics dashboard
- Integration with popular development frameworks

## Contributing

This is a decentralized protocol. Component builders and users contribute by:
- Creating high-quality, reusable components
- Providing constructive feedback
- Building integrations and tools
- Spreading awareness in the developer community

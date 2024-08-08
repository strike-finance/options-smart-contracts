# Project Name

## Table of Contents
- [Introduction](#introduction)
- [What Are Options](#what-are-options)
- [Technical High-Level Overview](#technical-high-level-overview)
- [Smart Contract Implementation](#smart-contract-implementation)
  - [Create Option](#create-option)
  - [Cancel Option](#cancel-option)
  - [Bid Option](#bid-option)
  - [Cancel Bid](#cancel-bid)
  - [Buy Option](#buy-option)
  - [Accept Bid](#accept-bid)
  - [Change Sale Price](#change-sale-price)
  - [Hold Option](#hold-option)
  - [Exercise Option](#exercise-option)
- [Links](#links)

## Introduction
V1 implementation of options trading on Strike Finance will be p2p. We understand Cardano has a liquidity problem and is currently exploring a pooled options alternative. This is an American Options platform, where users will have the right, but not the obligation, to exercise their contracts

## What Are Options
An option contract gives the holder the right to buy or sell an asset at a predetermined price before a certain date. In an options contract, there are puts and call options. A put option allows the holder to sell an asset at a specific price and a call option allows the holder to buy an asset at a specific price. Traders will buy put options when they anticipate an asset will decline in value and traders will buy call options when they anticipate an asset rise in value.

## Technical High-Level Overview
No assets are minted or burned in any interaction with the contract. Creating an option involves locking UTxOs at the script. Since there's no way to validate the creation of option data in this architecture, the Strike Finance platform will ignore malicious option UTxOs and only show users valid ones. Actions will simply update fields in the data. For example, buying or selling an option will update the current owner field in the data.
A stablecoin will always be on at least one side of the exchange. When creating an option contract, the issuer must lock up assets in the UTxO. The assets locked in the UTxO determine whether it's a put or call option:

**Call Option:**

* Gives the right to buy assets at a certain price
* Issuer locks up ADA or other CNTs
* When exercised, the holder sends stablecoins to the issuer and redeems the locked ADA or CNTs


**Put Option:**

* Gives the right to sell ADA or CNTs at a certain price
* Issuer locks up stablecoins
* When exercised, the holder sends ADA or CNTs to the issuer and receives stablecoins


## Smart Contract Implementation
[Your smart contract implementation overview here]

### Create Option
[Details about creating an option]

### Cancel Option
[Details about canceling an option]

### Bid Option
[Details about bidding on an option]

### Cancel Bid
[Details about canceling a bid]

### Buy Option
[Details about buying an option]

### Accept Bid
[Details about accepting a bid]

### Change Sale Price
[Details about changing the sale price]

### Hold Option
[Details about holding an option]

### Exercise Option
[Details about exercising an option]

## Links
[Your relevant links here]

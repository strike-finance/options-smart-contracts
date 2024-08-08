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
- [Future Features](#future-features)

## Introduction
V1 implementation of options trading on Strike Finance will be p2p. We understand Cardano has a liquidity problem and is currently exploring a pooled options alternative. This is an American Options platform, where users will have the right, but not the obligation, to exercise their contracts

## What Are Options
An option contract gives the holder the right to buy or sell an asset at a predetermined price before a certain date. In an options contract, there are puts and call options. A put option allows the holder to sell an asset at a specific price and a call option allows the holder to buy an asset at a specific price. Traders will buy put options when they anticipate an asset will decline in value and traders will buy call options when they anticipate an asset rise in value.

## Technical High-Level Overview
The on-chain code is written in Aiken.

No assets are minted or burned in any interaction with the contract. Creating an option involves locking UTxOs at the script. Since there's no way to validate the creation of option data in this architecture, the Strike Finance platform will ignore malicious option UTxOs and only show users valid ones. Actions will simply update fields in the data. For example, buying or selling an option will update the current owner field in the data.



A stablecoin will always be on at least one side of the exchange. When creating an option contract, the issuer must lock up assets in the UTxO. The assets locked in the UTxO determine whether it's a put or call option. Buying and selling options will also be settled in stablecoins.

**Call Option:**

* Gives the right to buy assets at a certain price
* Issuer locks up ADA or other CNTs
* When exercised, the holder sends stablecoins to the issuer and redeems the locked ADA or CNTs


**Put Option:**

* Gives the right to sell ADA or CNTs at a certain price
* Issuer locks up stablecoins
* When exercised, the holder sends ADA or CNTs to the issuer and receives stablecoins


## Smart Contract Implementation

### Create Option
The following fields are in an Option UTxO
```
pub type OptionDatum {
  issuer_pub_key_hash: AddressHash,
  issuer_bech32_address: ByteArray,
  current_owner_pub_key_hash: AddressHash,
  current_owner_bech32_address: ByteArray,
  from_asset: AssetClass,
  from_asset_amount: Int,
  to_asset: AssetClass,
  to_asset_amount: Int,
  sell_stablecoin_amount: Int,
  highest_bid: Int,
  highest_bidder_pub_key_hash: AddressHash,
  highest_bidder_address: ByteArray,
  deadline: Int,
  commission: Int,
}
```
Since there is no way to enforce UTxOs being sent to the script address, the Strike Finance platform will simply ignore malicious UTxOs. The from_asset field determines what the issuer of the contract locks up in the contract.

### Cancel Option
These are the following validations for cancelling an option. When cancelling an option, the assets locked up in the UTxO will be sent back to the issuer

**Validations Logic**
* If the current owner of option contract is the issuer, it simply checks if the assets are being returned to the issuer
* If the current owner of the option is not the issuer, it can only cancel the option if the deadline has passed. 
* If there are bids, the bid asset(stablecoin) must be returned to the bidder.

### Bid Option
Users can place bids on an option if they think the current ask price of the option contract is too high. 

**Validations Logic**
* The new bid must be higher than the previous highest bid
* If there is a previous highest bid, stablecoins must be returned back to the previous highest bidder

### Cancel Bid
Users can cancel a bid they placed

**Validations Logic**
* The bid assets are being send back to the bidder

### Buy Option
If a user deems an option contract attractive they can buy it directly without placing a bid. When buying an options contract, the datum of the of the UTxO will reflect that of the new owner.

**Validations Logic**
* The `sell_stablecoin_amount` must be send to the current owner
* The `sell_stablecoin_amount` must be higher than 0
* A percentage of the `sell_stablecoin_amount `specified in `commission` must be sent to the issuer. EX. If an options contracts ask price is 200 USDM and the commission is 10. To buy this contract, 200 USDM needs to be send to the holder, and 20 USDM needs to be send to the issuer
* If there is currently a bid, the bid assets must be send back to the bidder
* The UTxO being sent back to the script's datum only has the owner fields and bidders fields updated. Everything else is the same. The new `sell_stablecoin_amount` of the option is 0.
* The assets locked by the issuer are not consumed 

### Accept Bid
The owner of the option contract can accept a bid placed on the option. 

**Validations Logic**
* The new owner is the bidder
* The transaction needs to be signed by the owner
* A commission is sent to the issuer
* The new `sell_stablecoin_amount` of the option is 0
* The assets locked by the issuer are not consumed 

### Change Sale Price
**Disclaimer** We are in the process of intergrating Orcafax to dynamically price the option contract based on the price of the underlying asset

The owner of the option contract can change the sale price of the option based on current market condition
**Validations Logic**
* Signed by the current owner
* No assets in the UTxO are consumed, the current bid and the assets locked by the issuer

### Hold Option
The owner of the option contract 

### Exercise Option
[Details about exercising an option]

## Links
[Your relevant links here]

## Future Features

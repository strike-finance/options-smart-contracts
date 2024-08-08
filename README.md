# Strike Finance Options Smart Contract

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
This repo contains the smart contract for options trading on Strike Finance. V1 implementation of options trading on Strike Finance will be p2p (peer-to-peer). We understand Cardano has a liquidity problem and is currently exploring a pooled options alternative. This is an American Options platform, where users will have the right, but not the obligation, to exercise their contracts.

## What Are Options
An option contract gives the holder the right to buy or sell an asset at a predetermined price before a certain date. In options contracts, there are puts and calls. A put option allows the holder to sell an asset at a specific price, while a call option allows the holder to buy an asset at a specific price. Traders buy put options when they anticipate an asset will decline in value and call options when they anticipate an asset will rise in value.

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
The following fields are in an Option UTxO:
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
Since there is no way to enforce UTxOs being sent to the script address, the Strike Finance platform will simply ignore malicious UTxOs. The `from_asset` field determines what the issuer of the contract locks up in the contract.

### Cancel Option
**Validation Logic:**
* If the current owner of the option contract is the issuer, the contract checks if the assets are being returned to the issuer.
* If the current owner of the option is not the issuer, they can only cancel the option if the deadline has passed.
* If there are bids, the bid asset (stablecoin) must be returned to the bidder.

When cancelling an option, the assets locked up in the UTxO will be sent back to the issuer.

### Bid Option
Users can place bids on an option if they think the current ask price of the option contract is too high.

**Validation Logic:**
* The new bid must be higher than the previous highest bid.
* If there is a previous highest bid, stablecoins must be returned to the previous highest bidder.

### Cancel Bid
Users can cancel a bid they placed.

**Validation Logic:**
* The bid assets are being sent back to the bidder.

### Buy Option
If a user deems an option contract attractive, they can buy it directly without placing a bid. When buying an options contract, the datum of the UTxO will reflect that of the new owner.

**Validation Logic:**
* The `sell_stablecoin_amount` must be sent to the current owner.
* The `sell_stablecoin_amount` must be higher than 0.
* A percentage of the `sell_stablecoin_amount` specified in `commission` must be sent to the issuer. For example, if an option contract's ask price is 200 USDM and the commission is 10%, to buy this contract, 200 USDM needs to be sent to the holder, and 20 USDM needs to be sent to the issuer.
* If there is currently a bid, the bid assets must be sent back to the bidder.
* The UTxO being sent back to the script's datum only has the owner fields and bidder fields updated. Everything else remains the same. The new `sell_stablecoin_amount` of the option is 0.
* The assets locked by the issuer are not consumed.

### Accept Bid
The owner of the option contract can accept a bid placed on the option.

**Validation Logic:**
* The new owner is the bidder.
* The transaction needs to be signed by the owner.
* A commission is sent to the issuer.
* The new `sell_stablecoin_amount` of the option is 0.
* The assets locked by the issuer are not consumed.

### Change Sale Price
**Disclaimer:** We are in the process of integrating Orcafax to dynamically price the option contract based on the price of the underlying asset.

The owner of the option contract can change the sale price of the option based on current market conditions. If it was previously off the market, they can put it on the market by setting a sale price.

**Validation Logic:**
* The transaction is signed by the current owner.
* No assets in the UTxO are consumed, including the current bid and the assets locked by the issuer.

### Hold Option
The owner of the option contract can take their options contract off the market by setting the `sell_stablecoin_amount` to 0.

**Validation Logic:**
* The transaction is signed by the current owner.
* No assets in the UTxO are consumed, including the current bid and the assets locked by the issuer.

### Exercise Option
Once the option contract becomes profitable to execute, the owner of the option contract can exercise it.

**Validation Logic:**
* If there are currently bids on the options, the bid assets are sent back to the bidder.
* The deadline has not passed.
* The holder sends the correct amount of assets to the issuer specified in `from_asset` and `from_asset_amount`.
* The transaction is signed by the current owner.

## Links
- [Website](https://www.strikefinance.org/options)
- [Documentation](https://docs.strikefinance.org/)
- [Platform Walkthrough](https://www.youtube.com/watch?v=qo4NNxbN4ZM&t=2s)

## Future Features

1. If the option is not exercised by the owner by the deadline, the assets the issuer locked up should automatically be returned to the issuer through an off-chain bot.
2. The pricing of the options contracts needs to be dynamic and change as the underlying asset's price changes.

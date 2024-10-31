## Overview

- All interactions will be with a single UTxO at a single script address. This is a multivalidator with a spending and minting script. The validator is parameterized by the underlying asset(which is not used anywhere), stable coin asset, and the asset_name.

## Validations

## Smart Contract Implementation

### Create Option

This is the datum of an option UTxO.

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
  stable_asset: AssetClass,
  sell_stable_asset_amount: Int,
  highest_bid: Int,
  highest_bidder_pub_key_hash: AddressHash,
  highest_bidder_address: ByteArray,
  deadline: Int,
  commission: Int,
  minted_asset: AssetClass,
}
```

To create a option, the minting script checks

- The from_asset and the specified amount in the from_asset is valid
- the deadline has not past
- the minted asset is sent to the options script

### Cancel Option

**Validation Logic:**

- If the current owner of the option contract is the issuer, the contract checks if the assets are being returned to the issuer.
- If the current owner of the option is not the issuer, they can only cancel the option if the deadline has passed.
- If there are bids, the bid asset (stablecoin) must be returned to the bidder.

When cancelling an option, the assets locked up in the UTxO will be sent back to the issuer.

### Bid Option

Users can place bids on an option if they think the current ask price of the option contract is too high.

**Validation Logic:**

- The new bid must be higher than the previous highest bid.
- If there is a previous highest bid, stablecoins must be returned to the previous highest bidder.

### Cancel Bid

Users can cancel a bid they placed.

**Validation Logic:**

- The bid assets are being sent back to the bidder.

### Buy Option

If a user deems an option contract attractive, they can buy it directly without placing a bid. When buying an options contract, the datum of the UTxO will reflect that of the new owner.

**Validation Logic:**

- The `sell_stable_asset_amount` must be sent to the current owner.
- The `sell_stable_asset_amount` must be higher than 0.
- A percentage of the `sell_stable_asset_amount` specified in `commission` must be sent to the issuer. For example, if an option contract's ask price is 200 USDM and the commission is 10%, to buy this contract, 200 USDM needs to be sent to the holder, and 20 USDM needs to be sent to the issuer.
- If there is currently a bid, the bid assets must be sent back to the bidder.
- The UTxO being sent back to the script's datum only has the owner fields and bidder fields updated. Everything else remains the same. The new `sell_stable_asset_amount` of the option is 0.
- The assets locked by the issuer are not consumed.

### Accept Bid

The owner of the option contract can accept a bid placed on the option.

**Validation Logic:**

- The new owner is the bidder.
- The transaction needs to be signed by the owner.
- A commission is sent to the issuer.
- The new `sell_stable_asset_amount` of the option is 0.
- The assets locked by the issuer are not consumed.

### Change Sale Price

**Disclaimer:** We are in the process of integrating Orcafax to dynamically price the option contract based on the price of the underlying asset.

The owner of the option contract can change the sale price of the option based on current market conditions. If it was previously off the market, they can put it on the market by setting a sale price.

**Validation Logic:**

- The transaction is signed by the current owner.
- No assets in the UTxO are consumed, including the current bid and the assets locked by the issuer.

### Hold Option

The owner of the option contract can take their options contract off the market by setting the `sell_stable_asset_amount` to 0.

**Validation Logic:**

- The transaction is signed by the current owner.
- No assets in the UTxO are consumed, including the current bid and the assets locked by the issuer.

### Exercise Option

Once the option contract becomes profitable to execute, the owner of the option contract can exercise it.

**Validation Logic:**

- If there are currently bids on the options, the bid assets are sent back to the bidder.
- The deadline has not passed.
- The holder sends the correct amount of assets to the issuer specified in `from_asset` and `from_asset_amount`.
- The transaction is signed by the current owner.

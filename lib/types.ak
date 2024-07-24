use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value.{AssetName, PolicyId}

pub type AssetClass {
  policy_id: PolicyId,
  asset_name: AssetName,
}

pub type AddressHash =
  Hash<Blake2b_224, VerificationKey>

pub type POSIXTime =
  Int

pub type LovelaceAmount =
  Int

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
  action_code: Int,
}
// Action code for off-chain understanding of transaction
// 0: Create Option
// 1. Buy Option
// 2: Change Sell Price
// 3: Place Bid
// 4: Cancel Bid
// 5: Accept Bid

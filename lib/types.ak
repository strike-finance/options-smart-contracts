use aiken/crypto.{Blake2b_224, Hash, VerificationKey}
use cardano/assets.{AssetName, PolicyId}

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
  stable_asset: AssetClass,
  sell_stable_asset_amount: Int,
  highest_bid: Int,
  highest_bidder_pub_key_hash: AddressHash,
  highest_bidder_address: ByteArray,
  deadline: Int,
  commission: Int,
  minted_asset: AssetClass,
}

pub type Redeemer {
  BuyOption(Int, Int, Int, Int)
  ChangeSellPrice(Int, Int)
  ExerciseOption(Int, Int)
  CancelOption(Int)
  PlaceBid(Int, Int)
  CancelBid(Int)
  AcceptBid(Int, Int)
}

pub type MintRedeemer {
  Mint(Int)
  Burn
}

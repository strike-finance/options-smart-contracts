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
  issuer_address_hash: AddressHash,
  issuer_bech32_address: ByteArray,
  current_owner_address_hash: AddressHash,
  current_owner_bech32_address: ByteArray,
  sell_stablecoin_amount: Int,
  from_asset: AssetClass,
  from_asset_amount: Int,
  to_asset: AssetClass,
  to_asset_amount: Int,
  deadline: Int,
  commission: Int,
}

use aiken/crypto.{Blake2b_224, Hash, VerificationKey}
use cardano/assets.{PolicyId}

type PosixTime =
  Int

pub type AddressHash =
  Hash<Blake2b_224, VerificationKey>

pub type AssetClass {
  policy_id: PolicyId,
  asset_name: ByteArray,
}

pub type PriceMap =
  Pairs<Int, Int>

/// Represents different types of price data
pub type PriceData {
  /// Placeholder for shared data across multiple oracles
  SharedData
  /// Placeholder for extended data with additional information
  ExtendedData
  /// Generic data structure for price information
  GenericData { price_map: PriceMap }
}

/// Represents the main oracle datum structure
pub type OracleDatum {
  price_data: PriceData,
}

pub type OptionDatum {
  from_asset: AssetClass,
  from_asset_amount: Int,
  to_asset: AssetClass,
  to_asset_amount: Int,
  expiration_date: PosixTime,
  owner_address_hash: AddressHash,
  pool_script_hash: AddressHash,
  pool_script_address: ByteArray,
}

pub type PoolDatum {
  from_asset: AssetClass,
  from_asset_amount: Int,
}

pub type OptionRedeemer {
  SellOption
  ExerciseOption
  SendBackAsset
}

pub type WithdrawRedeemer {
  BuyOption
  WithdrawSellOption
}

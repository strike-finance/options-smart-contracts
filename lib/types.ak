use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{VerificationKey}

pub type AddressHash =
  Hash<Blake2b_224, VerificationKey>

pub type POSIXTime =
  Int

pub type LovelaceAmount =
  Int

pub type OptionDatum {
  issuer_address_hash: AddressHash,
  lovelace_amount: Int,
  usdm_amount: Int,
  current_owner_address_hash: AddressHash,
  sell_lovelace_amount: Int,
  deadline: Int,
  sell_percent: Int,
}

use aiken/collection/list
use cardano/assets.{quantity_of}
use cardano/transaction.{
  Output, OutputReference, Transaction, find_script_outputs,
}
use types.{
  AddressHash, ExerciseOption, OptionDatum, OptionRedeemer, SellOption,
  SendBackAsset,
}
use utils.{get_lower_bound, total_outputs_to_pool_script}

// from_asset sent to the pool, has not expired, signed by owner
fn validate_sell_option(
  datum: Option<OptionDatum>,
  transaction: Transaction,
  validated_signature: AddressHash,
) -> Bool {
  expect Some(datum) = datum

  let must_be_signed_by_owner =
    list.has(transaction.extra_signatories, datum.owner_address_hash)

  let has_not_expired =
    get_lower_bound(transaction.validity_range) < datum.expiration_date

  let outputs_to_pool_script: List<Output> =
    find_script_outputs(transaction.outputs, datum.pool_script_hash)
  let total_outputs_to_pool_script: Int =
    total_outputs_to_pool_script(outputs_to_pool_script)

  let asset_amount_valid =
    total_outputs_to_pool_script >= datum.from_asset_amount
  let signed_by_validated_signature =
    list.has(transaction.extra_signatories, validated_signature)

  signed_by_validated_signature && must_be_signed_by_owner && has_not_expired && asset_amount_valid
}

// to_asset sent to the pool, has not expired, signed by owner
fn validate_exercise_option(
  datum: Option<OptionDatum>,
  transaction: Transaction,
  validated_signature: AddressHash,
) -> Bool {
  expect Some(datum) = datum

  let must_be_signed_by_owner =
    list.has(transaction.extra_signatories, datum.owner_address_hash)

  let has_not_expired =
    get_lower_bound(transaction.validity_range) < datum.expiration_date

  let outputs_to_pool_script: List<Output> =
    find_script_outputs(transaction.outputs, datum.pool_script_hash)

  expect Some(output_to_pool_script) = list.head(outputs_to_pool_script)

  let to_asset_amount =
    quantity_of(
      output_to_pool_script.value,
      datum.to_asset.policy_id,
      datum.to_asset.asset_name,
    )

  let asset_amount_valid = to_asset_amount >= datum.to_asset_amount

  let signed_by_validated_signature =
    list.has(transaction.extra_signatories, validated_signature)

  trace @"validate_exercise_option"
  signed_by_validated_signature && must_be_signed_by_owner && has_not_expired && asset_amount_valid
}

// assets are sent back to the pool, has expired, signed by owner
fn validate_send_back_asset(
  datum: Option<OptionDatum>,
  transaction: Transaction,
  validated_signature: AddressHash,
) -> Bool {
  expect Some(datum) = datum

  let has_expired =
    get_lower_bound(transaction.validity_range) < datum.expiration_date

  let outputs_to_pool_script: List<Output> =
    find_script_outputs(transaction.outputs, datum.pool_script_hash)

  let total_outputs_to_pool_script =
    total_outputs_to_pool_script(outputs_to_pool_script)

  let asset_amount_valid =
    total_outputs_to_pool_script >= datum.from_asset_amount

  let signed_by_validated_signature =
    list.has(transaction.extra_signatories, validated_signature)

  signed_by_validated_signature && has_expired && asset_amount_valid
}

validator options(validated_signature: AddressHash) {
  spend(
    datum: Option<OptionDatum>,
    redeemer: OptionRedeemer,
    _my_output_reference: OutputReference,
    transaction: Transaction,
  ) {
    when redeemer is {
      SellOption ->
        validate_sell_option(datum, transaction, validated_signature)
      ExerciseOption ->
        validate_exercise_option(datum, transaction, validated_signature)
      SendBackAsset ->
        validate_send_back_asset(datum, transaction, validated_signature)
    }
  }

  else(_) {
    fail
  }
}

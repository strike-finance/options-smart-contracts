use aiken/list
use aiken/transaction.{Output, ScriptContext, find_script_outputs}
use aiken/transaction/value.{quantity_of}
use types.{OptionDatum}
use utils.{get_lower_bound}

type RedeemerAction {
  SellOption
  ExerciseOption
  SendBackAsset
}

type Redeemer {
  action: RedeemerAction,
}

// from_asset sent to the pool, has not expired, signed by owner
fn validate_sell_option(datum: OptionDatum, ctx: ScriptContext) -> Bool {
  let must_be_signed_by_owner =
    list.has(ctx.transaction.extra_signatories, datum.owner_address_hash)

  let has_not_expired =
    get_lower_bound(ctx.transaction.validity_range) > datum.expiration_date

  let outputs_to_options_script: List<Output> =
    find_script_outputs(ctx.transaction.outputs, datum.pool_script_hash)

  expect Some(output_to_options_script) = list.head(outputs_to_options_script)

  let from_asset_amount =
    quantity_of(
      output_to_options_script.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let asset_amount_valid = from_asset_amount >= datum.from_asset_amount

  must_be_signed_by_owner && has_not_expired && asset_amount_valid
}

// to_asset sent to the pool, has not expired, signed by owner
fn validate_exercise_option(datum: OptionDatum, ctx: ScriptContext) -> Bool {
  let must_be_signed_by_owner =
    list.has(ctx.transaction.extra_signatories, datum.owner_address_hash)

  let has_not_expired =
    get_lower_bound(ctx.transaction.validity_range) > datum.expiration_date

  let outputs_to_options_script: List<Output> =
    find_script_outputs(ctx.transaction.outputs, datum.pool_script_hash)

  expect Some(output_to_options_script) = list.head(outputs_to_options_script)

  let to_asset_amount =
    quantity_of(
      output_to_options_script.value,
      datum.to_asset.policy_id,
      datum.to_asset.asset_name,
    )

  let asset_amount_valid = to_asset_amount >= datum.to_asset_amount

  must_be_signed_by_owner && has_not_expired && asset_amount_valid
}

// assets are sent back to the pool, hash not expired, signed by owner
fn validate_send_back_asset(datum: OptionDatum, ctx: ScriptContext) -> Bool {
  let has_expired =
    get_lower_bound(ctx.transaction.validity_range) < datum.expiration_date

  let outputs_to_options_script: List<Output> =
    find_script_outputs(ctx.transaction.outputs, datum.pool_script_hash)

  expect Some(output_to_options_script) = list.head(outputs_to_options_script)

  let from_asset_amount =
    quantity_of(
      output_to_options_script.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let asset_amount_valid = from_asset_amount >= datum.from_asset_amount

  has_expired && asset_amount_valid
}

validator {
  fn spend(datum: OptionDatum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    when redeemer.action is {
      SellOption -> validate_sell_option(datum, ctx)
      ExerciseOption -> validate_exercise_option(datum, ctx)
      SendBackAsset -> validate_send_back_asset(datum, ctx)
    }
  }
}

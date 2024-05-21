use aiken/list
use aiken/transaction.{InlineDatum, Input, Output, ScriptContext, Spend}
use aiken/transaction/credential.{Address, from_verification_key}
use aiken/transaction/value.{lovelace_of}
use types.{LovelaceAmount, OptionDatum}
use utils.{get_lovelace_to_address}

type LoanRedeemer {
  SellOption
  ChangeSellPrice
  RealizeOption
  OriginalOwnerGetBack
}

type Redeemer {
  action: LoanRedeemer,
}

// sell_amount paid to current owner
// deadline has not passed
// percentage paid to original owner 
// least ada per sell to issuer is 2 ada
// sale price cannot be 0 
fn sell_option_valid(datum: OptionDatum, ctx: ScriptContext) {
  let current_owner_address: Address =
    from_verification_key(datum.current_owner_address_hash)
  let amount_to_current_owner: LovelaceAmount =
    get_lovelace_to_address(ctx.transaction.outputs, current_owner_address)

  let amount_to_current_owner_valid: Bool =
    amount_to_current_owner == datum.sell_lovelace_amount

  let issuer_address: Address = from_verification_key(datum.issuer_address_hash)

  let amount_to_issuer: LovelaceAmount =
    get_lovelace_to_address(ctx.transaction.outputs, issuer_address)

  let amount_to_issuer_valid: Bool =
    amount_to_issuer > datum.sell_lovelace_amount * datum.commission || amount_to_issuer > datum.sell_lovelace_amount * datum.commission && amount_to_current_owner == 2000000

  let is_for_sale = datum.sell_lovelace_amount > 0

  expect Spend(my_output_reference) = ctx.purpose

  expect Some(input_from_validator) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  let lovelace_amount_locked: Int =
    lovelace_of(input_from_validator.output.value)

  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)

  expect Some(output_to_validator) = list.at(outputs_to_validator, 0)

  let lovelace_amount_send_back: Int = lovelace_of(output_to_validator.value)

  let only_one_validtaor_output: Bool = list.length(outputs_to_validator) == 1

  let lovelace_amount_same: Bool =
    lovelace_amount_locked == lovelace_amount_send_back

  let deadline_not_passed: Bool =
    datum.deadline > utils.get_lower_bound(ctx.transaction.validity_range)

  is_for_sale && amount_to_current_owner_valid && deadline_not_passed && amount_to_issuer_valid && only_one_validator_input && only_one_validtaor_output && lovelace_amount_same
}

// deadline not passed, original owner signed transaction
// tokens are being sent to be locked up 
fn realize_option_valid(ctx: ScriptContext) {
  True
}

// only sale price changed 
fn change_sell_price_valid(ctx: ScriptContext) {
  expect Spend(my_output_reference) = ctx.purpose
  expect Some(input) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)
  expect InlineDatum(input_datum) = input.output.datum
  expect input_datum_typed: OptionDatum = input_datum

  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)
  expect Some(output) = list.at(outputs_to_validator, 0)
  expect InlineDatum(output_datum) = output.datum
  expect output_datum_typed: OptionDatum = output_datum

  let only_one_validtaor_output: Bool = list.length(outputs_to_validator) == 1
  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let sell_lovelace_amount_same: Bool =
    input_datum_typed.sell_lovelace_amount == output_datum_typed.sell_lovelace_amount

  let commission_same: Bool =
    input_datum_typed.commission != output_datum_typed.commission

  let deadline_same: Bool =
    input_datum_typed.deadline != output_datum_typed.deadline

  let issuer_address_hash_same: Bool =
    input_datum_typed.issuer_address_hash != output_datum_typed.issuer_address_hash

  let current_owner_address_hash_same: Bool =
    input_datum_typed.current_owner_address_hash != output_datum_typed.current_owner_address_hash

  let original_owner_address_hash_same: Bool =
    input_datum_typed.issuer_address_hash != output_datum_typed.issuer_address_hash

  let to_asset_same: Bool =
    input_datum_typed.to_asset == output_datum_typed.to_asset

  let to_asset_amount_same: Bool =
    input_datum_typed.to_asset_amount == output_datum_typed.to_asset_amount

  let from_asset_same: Bool =
    input_datum_typed.from_asset == output_datum_typed.from_asset

  let from_asset_amount_same: Bool =
    input_datum_typed.from_asset_amount == output_datum_typed.from_asset_amount

  only_one_validator_input && only_one_validtaor_output && sell_lovelace_amount_same && commission_same && deadline_same && issuer_address_hash_same && current_owner_address_hash_same && original_owner_address_hash_same && to_asset_same && to_asset_amount_same && from_asset_same && from_asset_amount_same
}

fn original_owner_get_back_valid(ctx: ScriptContext, datum: OptionDatum) {
  let must_be_signed_by_lender =
    list.has(ctx.transaction.extra_signatories, datum.issuer_address_hash)
  must_be_signed_by_lender
}

validator {
  fn spend(datum: OptionDatum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    when redeemer.action is {
      SellOption -> sell_option_valid(datum, ctx)

      ChangeSellPrice -> change_sell_price_valid(ctx)

      RealizeOption -> realize_option_valid(ctx)

      OriginalOwnerGetBack -> original_owner_get_back_valid(ctx, datum)
    }
  }
}

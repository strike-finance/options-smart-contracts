use aiken/list
use aiken/transaction.{InlineDatum, Input, Output, ScriptContext, Spend}
use aiken/transaction/credential.{Address, from_verification_key}
use aiken/transaction/value.{Value, from_asset, quantity_of}
use types.{LovelaceAmount, OptionDatum}
use utils.{get_lovelace_to_address}

type LoanRedeemer {
  SellOption
  ChangeSellPrice
  ExerciseOption
  IssuerGetBackAsset
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
  let is_for_sale: Bool = datum.sell_lovelace_amount > 0

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

  expect Spend(my_output_reference) = ctx.purpose
  expect Some(input_from_validator) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)
  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)
  expect Some(output_to_validator) = list.at(outputs_to_validator, 0)
  let only_one_validtaor_output: Bool = list.length(outputs_to_validator) == 1

  let asset_locked: Int =
    quantity_of(
      input_from_validator.output.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let asset_send_back: Int =
    quantity_of(
      output_to_validator.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let lovelace_amount_same: Bool = asset_locked == asset_send_back

  let deadline_not_passed: Bool =
    datum.deadline > utils.get_lower_bound(ctx.transaction.validity_range)

  let input_datum_info =
    OptionDatum {
      issuer_address_hash: datum.issuer_address_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_address_hash: "",
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      sell_lovelace_amount: 0,
      commission: datum.commission,
      deadline: datum.deadline,
    }

  let output_datum_info =
    OptionDatum {
      issuer_address_hash: datum.issuer_address_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_address_hash: "",
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      sell_lovelace_amount: 0,
      commission: datum.commission,
      deadline: datum.deadline,
    }

  is_for_sale && amount_to_current_owner_valid && deadline_not_passed && amount_to_issuer_valid && only_one_validator_input && only_one_validtaor_output && lovelace_amount_same && input_datum_info == output_datum_info
}

// deadline not passed, original owner signed transaction
// tokens are being sent to be owner
fn exercise_option_valid(datum: OptionDatum, ctx: ScriptContext) {
  let deadline_not_passed: Bool =
    utils.get_lower_bound(ctx.transaction.validity_range) < datum.deadline

  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)

  let only_one_validtaor_output: Bool = list.length(outputs_to_validator) == 1
  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let issuer_address: Address = from_verification_key(datum.issuer_address_hash)

  let outputs: List<Output> = ctx.transaction.outputs

  expect Some(output_to_address) =
    list.find(outputs, fn(output) { output.address == issuer_address })

  let expected_to_value: Value =
    from_asset(
      datum.to_asset.policy_id,
      datum.to_asset.asset_name,
      datum.to_asset_amount,
    )

  let to_asset_amount_same: Bool = output_to_address.value == expected_to_value

  let must_be_signed_by_owner =
    list.has(ctx.transaction.extra_signatories, datum.issuer_address_hash)

  must_be_signed_by_owner && deadline_not_passed && only_one_validator_input && only_one_validtaor_output && to_asset_amount_same
}

// only sale price changed 
fn change_sell_price_valid(datum: OptionDatum, ctx: ScriptContext) {
  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)
  expect Some(output) = list.at(outputs_to_validator, 0)
  expect InlineDatum(output_datum) = output.datum
  expect output_datum_typed: OptionDatum = output_datum

  let only_one_validtaor_output: Bool = list.length(outputs_to_validator) == 1
  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let input_datum_info =
    OptionDatum {
      issuer_address_hash: datum.issuer_address_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_address_hash: datum.current_owner_address_hash,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      sell_lovelace_amount: 0,
      commission: datum.commission,
      deadline: datum.deadline,
    }

  let output_datum_info =
    OptionDatum {
      issuer_address_hash: output_datum_typed.issuer_address_hash,
      issuer_bech32_address: output_datum_typed.issuer_bech32_address,
      current_owner_address_hash: output_datum_typed.current_owner_address_hash,
      to_asset: output_datum_typed.to_asset,
      to_asset_amount: output_datum_typed.to_asset_amount,
      from_asset: output_datum_typed.from_asset,
      from_asset_amount: output_datum_typed.from_asset_amount,
      sell_lovelace_amount: 0,
      deadline: output_datum_typed.deadline,
      commission: output_datum_typed.commission,
    }

  let deadline_not_passed: Bool =
    utils.get_lower_bound(ctx.transaction.validity_range) < datum.deadline

  let must_be_signed_by_owner =
    list.has(ctx.transaction.extra_signatories, datum.issuer_address_hash)

  must_be_signed_by_owner && deadline_not_passed && only_one_validator_input && only_one_validtaor_output && input_datum_info == output_datum_info
}

fn issuer_get_back_asset_valid(datum: OptionDatum, ctx: ScriptContext) {
  let must_be_signed_by_owner =
    list.has(ctx.transaction.extra_signatories, datum.issuer_address_hash)

  let deadline_passed: Bool =
    utils.get_lower_bound(ctx.transaction.validity_range) > datum.deadline

  must_be_signed_by_owner && deadline_passed
}

validator {
  fn spend(datum: OptionDatum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    when redeemer.action is {
      SellOption -> sell_option_valid(datum, ctx)

      ChangeSellPrice -> change_sell_price_valid(datum, ctx)

      ExerciseOption -> exercise_option_valid(datum, ctx)

      IssuerGetBackAsset -> issuer_get_back_asset_valid(datum, ctx)
    }
  }
}

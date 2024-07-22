use aiken/list
use aiken/transaction.{InlineDatum, Input, Output, ScriptContext, Spend}
use aiken/transaction/credential.{Address, from_verification_key}
use aiken/transaction/value.{AssetName, PolicyId, quantity_of}
use types.{LovelaceAmount, OptionDatum}
use utils.{get_asset_to_address}

type LoanRedeemer {
  BuyOption
  ChangeSellPrice
  ExerciseOption
  CancelOption
  PlaceBid
  CancelBid
  AcceptBid
}

type Redeemer {
  action: LoanRedeemer,
}

fn buy_option_valid(
  datum: OptionDatum,
  ctx: ScriptContext,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
) {
  let is_for_sale: Bool = datum.sell_stablecoin_amount > 0

  let current_owner_address: Address =
    from_verification_key(datum.current_owner_pub_key_hash)
  let amount_to_current_owner: Int =
    get_asset_to_address(
      ctx.transaction.outputs,
      current_owner_address,
      stable_policy_id,
      stable_asset_name,
    )
  let amount_to_current_owner_valid: Bool =
    amount_to_current_owner >= datum.sell_stablecoin_amount

  let issuer_address: Address = from_verification_key(datum.issuer_pub_key_hash)
  let amount_to_issuer: LovelaceAmount =
    get_asset_to_address(
      ctx.transaction.outputs,
      issuer_address,
      stable_policy_id,
      stable_asset_name,
    )
  let amount_to_issuer_valid: Bool =
    amount_to_issuer >= datum.sell_stablecoin_amount * datum.commission / 100

  expect Spend(my_output_reference) = ctx.purpose
  expect Some(input_from_validator) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)
  expect Some(output_to_validator) = list.at(outputs_to_validator, 0)
  expect InlineDatum(output_datum) = output_to_validator.datum
  expect output_datum_typed: OptionDatum = output_datum

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

  let compared_input_datum_info =
    OptionDatum {
      issuer_pub_key_hash: datum.issuer_pub_key_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_pub_key_hash: "",
      current_owner_bech32_address: "",
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      sell_stablecoin_amount: 0,
      highest_bid: 0,
      highest_bidder_pub_key_hash: "",
      highest_bidder_address: "",
      commission: datum.commission,
      deadline: datum.deadline,
    }

  let compared_output_datum_info =
    OptionDatum {
      issuer_pub_key_hash: datum.issuer_pub_key_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_pub_key_hash: "",
      current_owner_bech32_address: "",
      from_asset: datum.from_asset,
      from_asset_amount: asset_send_back,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      sell_stablecoin_amount: 0,
      highest_bid: 0,
      highest_bidder_pub_key_hash: "",
      highest_bidder_address: "",
      commission: datum.commission,
      deadline: datum.deadline,
    }

  let asset_not_consumed: Bool = asset_send_back >= asset_locked

  let deadline_not_passed: Bool =
    datum.deadline > utils.get_lower_bound(ctx.transaction.validity_range)

  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let only_one_validtaor_output: Bool = list.length(outputs_to_validator) == 1

  let datum_valid: Bool =
    compared_input_datum_info == compared_output_datum_info

  let has_bid: Bool = datum.highest_bid > 0

  let output_datum_valid: Bool =
    output_datum_typed.highest_bid == 0 && output_datum_typed.highest_bidder_pub_key_hash == "" && output_datum_typed.highest_bidder_address == ""

  let default_checks: Bool =
    is_for_sale && amount_to_current_owner_valid && deadline_not_passed && amount_to_issuer_valid && only_one_validator_input && only_one_validtaor_output && asset_not_consumed && datum_valid && output_datum_valid

  if has_bid {
    let asset_send_back_to_previous_bidder: Int =
      get_asset_to_address(
        ctx.transaction.outputs,
        from_verification_key(datum.highest_bidder_pub_key_hash),
        stable_policy_id,
        stable_asset_name,
      )

    let bid_returned_to_owner: Bool =
      asset_send_back_to_previous_bidder >= datum.highest_bid
    default_checks && bid_returned_to_owner
  } else {
    default_checks
  }
}

fn exercise_option_valid(
  datum: OptionDatum,
  ctx: ScriptContext,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
) {
  let deadline_not_passed: Bool =
    utils.get_lower_bound(ctx.transaction.validity_range) < datum.deadline

  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let issuer_address: Address = from_verification_key(datum.issuer_pub_key_hash)

  let outputs: List<Output> = ctx.transaction.outputs

  expect Some(output_to_address) =
    list.find(
      outputs,
      fn(output) {
        output.address.payment_credential == issuer_address.payment_credential
      },
    )

  let to_issuer_addrress_amount_valid: Bool =
    quantity_of(
      output_to_address.value,
      datum.to_asset.policy_id,
      datum.to_asset.asset_name,
    ) >= datum.to_asset_amount

  let must_be_signed_by_owner =
    list.has(
      ctx.transaction.extra_signatories,
      datum.current_owner_pub_key_hash,
    )

  let has_bid: Bool = datum.highest_bid > 0

  let default_checks: Bool =
    must_be_signed_by_owner && deadline_not_passed && only_one_validator_input && to_issuer_addrress_amount_valid

  if has_bid {
    let bid_returned_to_owner: Bool =
      get_asset_to_address(
        ctx.transaction.outputs,
        from_verification_key(datum.highest_bidder_pub_key_hash),
        stable_policy_id,
        stable_asset_name,
      ) >= datum.highest_bid

    default_checks && bid_returned_to_owner
  } else {
    default_checks
  }
}

fn change_sell_price_valid(
  datum: OptionDatum,
  ctx: ScriptContext,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
) {
  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)
  expect Some(output_to_validator) = list.at(outputs_to_validator, 0)
  expect InlineDatum(output_datum) = output_to_validator.datum
  expect output_datum_typed: OptionDatum = output_datum

  expect Spend(my_output_reference) = ctx.purpose
  expect Some(input_from_validator) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

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

  let bid_asset_locked: Int =
    quantity_of(
      input_from_validator.output.value,
      stable_policy_id,
      stable_asset_name,
    )

  let bid_asset_send_back: Int =
    quantity_of(output_to_validator.value, stable_policy_id, stable_asset_name)

  let bid_asset_not_consumed = bid_asset_locked == bid_asset_send_back

  let input_datum_info =
    OptionDatum {
      issuer_pub_key_hash: datum.issuer_pub_key_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_pub_key_hash: datum.current_owner_pub_key_hash,
      current_owner_bech32_address: datum.current_owner_bech32_address,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      sell_stablecoin_amount: 0,
      highest_bid: datum.highest_bid,
      highest_bidder_pub_key_hash: datum.highest_bidder_pub_key_hash,
      highest_bidder_address: datum.highest_bidder_address,
      commission: datum.commission,
      deadline: datum.deadline,
    }

  let output_datum_info =
    OptionDatum {
      issuer_pub_key_hash: output_datum_typed.issuer_pub_key_hash,
      issuer_bech32_address: output_datum_typed.issuer_bech32_address,
      current_owner_pub_key_hash: output_datum_typed.current_owner_pub_key_hash,
      current_owner_bech32_address: datum.current_owner_bech32_address,
      to_asset: output_datum_typed.to_asset,
      to_asset_amount: output_datum_typed.to_asset_amount,
      from_asset: output_datum_typed.from_asset,
      from_asset_amount: output_datum_typed.from_asset_amount,
      sell_stablecoin_amount: 0,
      highest_bid: datum.highest_bid,
      highest_bidder_pub_key_hash: datum.highest_bidder_pub_key_hash,
      highest_bidder_address: datum.highest_bidder_address,
      deadline: output_datum_typed.deadline,
      commission: output_datum_typed.commission,
    }

  let new_sale_price_larger_than_bid: Bool =
    output_datum_typed.sell_stablecoin_amount >= datum.highest_bid

  let only_one_validtaor_output: Bool = list.length(outputs_to_validator) == 1
  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let deadline_not_passed: Bool =
    utils.get_lower_bound(ctx.transaction.validity_range) < datum.deadline

  let must_be_signed_by_owner: Bool =
    list.has(
      ctx.transaction.extra_signatories,
      datum.current_owner_pub_key_hash,
    )

  let asset_locked_same: Bool = asset_locked == asset_send_back

  bid_asset_not_consumed && new_sale_price_larger_than_bid && must_be_signed_by_owner && deadline_not_passed && only_one_validator_input && only_one_validtaor_output && asset_locked_same && input_datum_info == output_datum_info
}

fn cancel_option_valid(
  datum: OptionDatum,
  ctx: ScriptContext,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
) {
  let must_be_signed_by_issuer: Bool =
    list.has(ctx.transaction.extra_signatories, datum.issuer_pub_key_hash)

  let deadline_passed: Bool =
    utils.get_lower_bound(ctx.transaction.validity_range) > datum.deadline

  let issuer_is_current_owner: Bool =
    datum.issuer_pub_key_hash == datum.current_owner_pub_key_hash

  let default_checks: Bool =
    must_be_signed_by_issuer && ( deadline_passed || issuer_is_current_owner )

  let has_bid: Bool = datum.highest_bid > 0

  if has_bid {
    let bid_returned_to_owner: Bool =
      get_asset_to_address(
        ctx.transaction.outputs,
        from_verification_key(datum.highest_bidder_pub_key_hash),
        stable_policy_id,
        stable_asset_name,
      ) >= datum.highest_bid

    default_checks && bid_returned_to_owner
  } else {
    default_checks
  }
}

fn place_bid_valid(
  datum: OptionDatum,
  ctx: ScriptContext,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
) {
  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)
  expect Some(output_to_validator) = list.at(outputs_to_validator, 0)
  expect InlineDatum(output_datum) = output_to_validator.datum
  expect output_datum_typed: OptionDatum = output_datum

  expect Spend(my_output_reference) = ctx.purpose
  expect Some(input_from_validator) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  let locked_asset: Int =
    quantity_of(
      input_from_validator.output.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let locked_asset_output: Int =
    quantity_of(
      output_to_validator.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let stable_asset_in_input: Int =
    quantity_of(
      input_from_validator.output.value,
      stable_policy_id,
      stable_asset_name,
    )

  let stable_asset_in_output: Int =
    quantity_of(output_to_validator.value, stable_policy_id, stable_asset_name)

  let only_one_validtaor_output: Bool = list.length(outputs_to_validator) == 1
  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(ctx)) == 1

  let deadline_not_passed: Bool =
    utils.get_lower_bound(ctx.transaction.validity_range) < datum.deadline

  let asset_not_consumed: Bool = locked_asset_output >= locked_asset

  let is_for_sale: Bool = datum.sell_stablecoin_amount > 0

  let datum_value_not_corrupted: Bool =
    datum.issuer_pub_key_hash == output_datum_typed.issuer_pub_key_hash && datum.issuer_bech32_address == output_datum_typed.issuer_bech32_address && datum.current_owner_pub_key_hash == output_datum_typed.current_owner_pub_key_hash && datum.current_owner_bech32_address == output_datum_typed.current_owner_bech32_address && datum.from_asset == output_datum_typed.from_asset && datum.from_asset_amount == output_datum_typed.from_asset_amount && datum.to_asset == output_datum_typed.to_asset && datum.to_asset_amount == output_datum_typed.to_asset_amount && datum.commission == output_datum_typed.commission && datum.deadline == output_datum_typed.deadline

  let output_bid_datum_correct: Bool =
    stable_asset_in_output - output_datum_typed.highest_bid >= stable_asset_in_input - datum.highest_bid

  let output_contains_correct_amount_of_stable_asset: Bool =
    stable_asset_in_output >= stable_asset_in_input - datum.highest_bid + output_datum_typed.highest_bid

  let default_checks: Bool =
    asset_not_consumed && is_for_sale && deadline_not_passed && only_one_validator_input && only_one_validtaor_output && output_bid_datum_correct && datum_value_not_corrupted && output_contains_correct_amount_of_stable_asset

  let has_bid: Bool = datum.highest_bid > 0

  if has_bid {
    let bid_returned_to_owner: Bool =
      get_asset_to_address(
        ctx.transaction.outputs,
        from_verification_key(datum.highest_bidder_pub_key_hash),
        stable_policy_id,
        stable_asset_name,
      ) >= datum.highest_bid

    let bid_higher_than_current: Bool =
      output_datum_typed.highest_bid > datum.highest_bid

    default_checks && bid_higher_than_current && bid_returned_to_owner
  } else {
    default_checks
  }
}

fn cancel_bid_valid(
  datum: OptionDatum,
  ctx: ScriptContext,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
) {
  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)
  expect Some(output_to_validator) = list.at(outputs_to_validator, 0)
  expect InlineDatum(output_datum) = output_to_validator.datum
  expect output_datum_typed: OptionDatum = output_datum

  expect Spend(my_output_reference) = ctx.purpose
  expect Some(input_from_validator) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  let stable_asset_in_input: Int =
    quantity_of(
      input_from_validator.output.value,
      stable_policy_id,
      stable_asset_name,
    )

  let stable_asset_in_output: Int =
    quantity_of(output_to_validator.value, stable_policy_id, stable_asset_name)

  let from_asset_in_input: Int =
    quantity_of(
      input_from_validator.output.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let from_asset_in_output: Int =
    quantity_of(
      output_to_validator.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let asset_not_consumed: Bool = from_asset_in_output >= from_asset_in_input

  let output_contains_correct_amount_of_stable_asset: Bool =
    stable_asset_in_input - datum.highest_bid == stable_asset_in_output

  let datum_value_not_corrupted: Bool =
    datum.issuer_pub_key_hash == output_datum_typed.issuer_pub_key_hash && datum.issuer_bech32_address == output_datum_typed.issuer_bech32_address && datum.current_owner_pub_key_hash == output_datum_typed.current_owner_pub_key_hash && datum.current_owner_bech32_address == output_datum_typed.current_owner_bech32_address && datum.from_asset == output_datum_typed.from_asset && datum.from_asset_amount == output_datum_typed.from_asset_amount && datum.to_asset == output_datum_typed.to_asset && datum.to_asset_amount == output_datum_typed.to_asset_amount && datum.commission == output_datum_typed.commission && datum.deadline == output_datum_typed.deadline

  let new_bid_valid: Bool =
    output_datum_typed.highest_bid == 0 && output_datum_typed.highest_bidder_pub_key_hash == "" && output_datum_typed.highest_bidder_address == ""

  let signed_by_bidder: Bool =
    list.has(
      ctx.transaction.extra_signatories,
      datum.highest_bidder_pub_key_hash,
    )

  datum_value_not_corrupted && output_contains_correct_amount_of_stable_asset && new_bid_valid && asset_not_consumed && signed_by_bidder
}

fn accept_bid_valid(
  datum: OptionDatum,
  ctx: ScriptContext,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
) {
  let outputs_to_validator: List<Output> = utils.get_validators_outputs(ctx)
  expect Some(output_to_validator) = list.at(outputs_to_validator, 0)
  expect InlineDatum(output_datum) = output_to_validator.datum
  expect output_datum_typed: OptionDatum = output_datum

  expect Spend(my_output_reference) = ctx.purpose
  expect Some(input_from_validator) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  let stable_asset_in_input: Int =
    quantity_of(
      input_from_validator.output.value,
      stable_policy_id,
      stable_asset_name,
    )

  let stable_asset_in_output: Int =
    quantity_of(output_to_validator.value, stable_policy_id, stable_asset_name)

  let signed_by_holder: Bool =
    list.has(
      ctx.transaction.extra_signatories,
      datum.current_owner_pub_key_hash,
    )

  let from_asset_in_input: Int =
    quantity_of(
      input_from_validator.output.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let from_asset_in_output: Int =
    quantity_of(
      output_to_validator.value,
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
    )

  let asset_not_consumed: Bool = from_asset_in_output >= from_asset_in_input

  let output_contains_correct_amount_of_stable_asset: Bool =
    stable_asset_in_output >= stable_asset_in_input - datum.highest_bid

  let datum_value_not_corrupted: Bool =
    datum.issuer_pub_key_hash == output_datum_typed.issuer_pub_key_hash && datum.issuer_bech32_address == output_datum_typed.issuer_bech32_address && datum.from_asset == output_datum_typed.from_asset && datum.from_asset_amount == output_datum_typed.from_asset_amount && datum.to_asset == output_datum_typed.to_asset && datum.to_asset_amount == output_datum_typed.to_asset_amount && datum.commission == output_datum_typed.commission && datum.deadline == output_datum_typed.deadline

  let new_owner_valid: Bool =
    output_datum_typed.current_owner_pub_key_hash == datum.highest_bidder_pub_key_hash && output_datum_typed.current_owner_bech32_address == datum.highest_bidder_address

  let new_bid_valid: Bool =
    output_datum_typed.highest_bid == 0 && output_datum_typed.highest_bidder_pub_key_hash == "" && output_datum_typed.highest_bidder_address == ""

  asset_not_consumed && signed_by_holder && datum_value_not_corrupted && output_contains_correct_amount_of_stable_asset && new_bid_valid && new_owner_valid
}

validator(stable_policy_id: PolicyId, stable_asset_name: AssetName) {
  fn spend(datum: OptionDatum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    when redeemer.action is {
      BuyOption ->
        buy_option_valid(datum, ctx, stable_policy_id, stable_asset_name)

      ChangeSellPrice ->
        change_sell_price_valid(datum, ctx, stable_policy_id, stable_asset_name)

      ExerciseOption ->
        exercise_option_valid(datum, ctx, stable_policy_id, stable_asset_name)

      CancelOption ->
        cancel_option_valid(datum, ctx, stable_policy_id, stable_asset_name)

      PlaceBid ->
        place_bid_valid(datum, ctx, stable_policy_id, stable_asset_name)

      CancelBid ->
        cancel_bid_valid(datum, ctx, stable_policy_id, stable_asset_name)

      AcceptBid ->
        accept_bid_valid(datum, ctx, stable_policy_id, stable_asset_name)
    }
  }
}

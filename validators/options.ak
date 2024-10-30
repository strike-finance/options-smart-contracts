use aiken/collection/list
use cardano/address.{Address, from_verification_key}
use cardano/assets.{AssetName, PolicyId, Value, flatten, match}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use types.{
  AcceptBid, Burn, BuyOption, CancelBid, CancelOption, ChangeSellPrice,
  ExerciseOption, Mint, MintRedeemer, OptionDatum, PlaceBid, Redeemer,
}
use utils.{get_script_hash, get_validators_inputs}

fn buy_option_valid(
  datum: OptionDatum,
  transaction: Transaction,
  output_to_script_index: Int,
  output_to_owner_index: Int,
  output_to_issuer_index: Int,
  output_to_bidder_index: Int,
) {
  expect Some(output_to_issuer) =
    list.at(transaction.outputs, output_to_issuer_index)

  expect Some(output_to_owner) =
    list.at(transaction.outputs, output_to_owner_index)

  let issuer_address = from_verification_key(datum.issuer_pub_key_hash)

  expect issuer_address == output_to_issuer.address

  let expected_commission_amount: Int =
    datum.sell_stable_asset_amount * datum.commission / 100

  if datum.issuer_pub_key_hash == datum.current_owner_pub_key_hash {
    let expected_assets_to_issuer =
      assets.from_asset(
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        datum.sell_stable_asset_amount,
      )

    let assets_to_issuer_valid =
      match(output_to_issuer.value, expected_assets_to_issuer, >=)

    expect assets_to_issuer_valid
  } else {
    let expected_assets_to_issuer =
      assets.from_asset(
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        expected_commission_amount,
      )

    let assets_to_issuer_valid =
      match(output_to_issuer.value, expected_assets_to_issuer, >=)

    let expected_assets_to_owner =
      assets.from_asset(
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        datum.sell_stable_asset_amount,
      )

    let assets_to_owner_valid =
      match(output_to_owner.value, expected_assets_to_owner, >=)

    let owner_address = from_verification_key(datum.current_owner_pub_key_hash)

    let output_to_owner_address_correct =
      owner_address == output_to_owner.address

    expect
      assets_to_issuer_valid && assets_to_owner_valid && output_to_owner_address_correct
  }

  let all_inputs_from_script = get_validators_inputs(transaction)
  let only_one_validator_input: Bool = list.length(all_inputs_from_script) == 1
  expect Some(input_from_validator) = list.head(all_inputs_from_script)

  expect Some(output_to_validator) =
    list.at(transaction.outputs, output_to_script_index)
  expect InlineDatum(output_datum) = output_to_validator.datum
  expect output_datum_typed: OptionDatum = output_datum

  let expected_assets_locked =
    assets.from_asset(
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
      datum.from_asset_amount,
    )
      |> assets.add(datum.minted_asset.policy_id, datum.minted_asset.asset_name, 1)

  let output_address_valid =
    output_to_validator.address == input_from_validator.output.address

  let assets_locked_valid =
    match(output_to_validator.value, expected_assets_locked, >=)

  let expected_datum =
    OptionDatum {
      issuer_pub_key_hash: datum.issuer_pub_key_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_pub_key_hash: output_datum_typed.current_owner_pub_key_hash,
      current_owner_bech32_address: output_datum_typed.current_owner_bech32_address,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      stable_asset: datum.stable_asset,
      sell_stable_asset_amount: 0,
      highest_bid: 0,
      highest_bidder_pub_key_hash: "",
      highest_bidder_address: "",
      deadline: datum.deadline,
      commission: datum.commission,
      minted_asset: datum.minted_asset,
    }

  let deadline_not_passed: Bool =
    datum.deadline > utils.get_lower_bound(transaction.validity_range)

  let datum_valid: Bool = expected_datum == output_datum_typed

  let is_for_sale: Bool = datum.sell_stable_asset_amount > 0

  expect
    is_for_sale && deadline_not_passed && only_one_validator_input && datum_valid && assets_locked_valid && output_address_valid

  let has_bid: Bool = datum.highest_bid > 0

  if has_bid {
    expect Some(output_to_bidder) =
      list.at(transaction.outputs, output_to_bidder_index)

    let expected_assets_to_bidder =
      assets.from_asset(
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        datum.highest_bid,
      )

    let assets_to_bidder_valid =
      match(output_to_bidder.value, expected_assets_to_bidder, >=)

    assets_to_bidder_valid
  } else {
    True
  }
}

fn change_sell_price_valid(
  datum: OptionDatum,
  transaction: Transaction,
  output_to_script_index: Int,
  output_to_bidder_index: Int,
) {
  let all_inputs_from_script = get_validators_inputs(transaction)
  let only_one_script_input: Bool = list.length(all_inputs_from_script) == 1
  expect Some(input_from_validator) = list.head(all_inputs_from_script)

  expect Some(output_back_to_script) =
    list.at(transaction.outputs, output_to_script_index)
  expect InlineDatum(output_datum) = output_back_to_script.datum
  expect output_datum_typed: OptionDatum = output_datum

  let output_address_valid: Bool =
    output_back_to_script.address == input_from_validator.output.address

  let expected_output_datum =
    OptionDatum {
      issuer_pub_key_hash: datum.issuer_pub_key_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_pub_key_hash: datum.current_owner_pub_key_hash,
      current_owner_bech32_address: datum.current_owner_bech32_address,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      stable_asset: datum.stable_asset,
      sell_stable_asset_amount: output_datum_typed.sell_stable_asset_amount,
      highest_bid: datum.highest_bid,
      highest_bidder_pub_key_hash: datum.highest_bidder_pub_key_hash,
      highest_bidder_address: datum.highest_bidder_address,
      deadline: datum.deadline,
      commission: datum.commission,
      minted_asset: datum.minted_asset,
    }

  let output_datum_correct: Bool = expected_output_datum == output_datum_typed

  let deadline_not_passed: Bool =
    utils.get_lower_bound(transaction.validity_range) < datum.deadline

  let must_be_signed_by_owner: Bool =
    list.has(transaction.extra_signatories, datum.current_owner_pub_key_hash)

  let expected_assets_sent_back: Value =
    assets.from_asset(
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
      datum.from_asset_amount,
    )
      |> assets.add(datum.minted_asset.policy_id, datum.minted_asset.asset_name, 1)

  expect
    output_address_valid && must_be_signed_by_owner && deadline_not_passed && only_one_script_input && output_datum_correct

  let hold_option: Bool = output_datum_typed.sell_stable_asset_amount == 0

  if hold_option && datum.highest_bid > 0 {
    expect Some(output_to_bidder) =
      list.at(transaction.outputs, output_to_bidder_index)

    let expected_assets_sent_to_bidder =
      assets.from_asset(
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        datum.highest_bid,
      )

    let assets_sent_to_bidder_valid =
      match(output_to_bidder.value, expected_assets_sent_to_bidder, >=)

    let expected_assets_sent_back_valid =
      match(output_back_to_script.value, expected_assets_sent_back, >=)

    assets_sent_to_bidder_valid && expected_assets_sent_back_valid
  } else if hold_option {
    match(output_back_to_script.value, expected_assets_sent_back, >=)
  } else {
    let new_sale_price_larger_than_bid: Bool =
      output_datum_typed.sell_stable_asset_amount >= datum.highest_bid

    let expected_assets_sent_back_with_bid =
      assets.add(
        expected_assets_sent_back,
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        datum.highest_bid,
      )

    let assets_sent_back_valid =
      match(output_back_to_script.value, expected_assets_sent_back_with_bid, >=)

    new_sale_price_larger_than_bid && assets_sent_back_valid
  }
}

fn exercise_option_valid(
  datum: OptionDatum,
  transaction: Transaction,
  output_to_issuer_index: Int,
  output_to_bidder_index: Int,
) {
  let deadline_not_passed: Bool =
    utils.get_lower_bound(transaction.validity_range) < datum.deadline

  let only_one_validator_input: Bool =
    list.length(utils.get_validators_inputs(transaction)) == 1

  let issuer_address: Address = from_verification_key(datum.issuer_pub_key_hash)

  expect Some(output_to_issuer) =
    list.at(transaction.outputs, output_to_issuer_index)

  let output_is_to_issuer = issuer_address == output_to_issuer.address

  let expected_assets_to_issuer =
    assets.from_asset(
      datum.to_asset.policy_id,
      datum.to_asset.asset_name,
      datum.to_asset_amount,
    )

  let assets_to_issuer_valid =
    match(output_to_issuer.value, expected_assets_to_issuer, >=)

  let must_be_signed_by_owner =
    list.has(transaction.extra_signatories, datum.current_owner_pub_key_hash)

  let has_bid: Bool = datum.highest_bid > 0

  let mint_valid =
    [(datum.minted_asset.policy_id, datum.minted_asset.asset_name, -1)] == flatten(
      transaction.mint,
    )

  expect
    must_be_signed_by_owner && deadline_not_passed && only_one_validator_input && assets_to_issuer_valid && output_is_to_issuer && mint_valid

  if has_bid {
    expect Some(output_to_bidder) =
      list.at(transaction.outputs, output_to_bidder_index)

    let bidder_address: Address =
      from_verification_key(datum.highest_bidder_pub_key_hash)

    let output_to_bidder_address_correct: Bool =
      bidder_address == output_to_bidder.address

    let expected_assets_to_bidder =
      assets.from_asset(
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        datum.highest_bid,
      )

    let assets_to_bidder_valid =
      match(output_to_bidder.value, expected_assets_to_bidder, >=)

    assets_to_bidder_valid && output_to_bidder_address_correct
  } else {
    True
  }
}

fn issuer_cancel_option_valid(
  datum: OptionDatum,
  transaction: Transaction,
  output_to_bidder_index: Int,
) {
  let must_be_signed_by_issuer: Bool =
    list.has(transaction.extra_signatories, datum.issuer_pub_key_hash)

  let deadline_passed: Bool =
    utils.get_lower_bound(transaction.validity_range) > datum.deadline

  let issuer_is_current_owner: Bool =
    datum.issuer_pub_key_hash == datum.current_owner_pub_key_hash

  let mint_valid =
    [(datum.minted_asset.policy_id, datum.minted_asset.asset_name, -1)] == flatten(
      transaction.mint,
    )

  expect
    must_be_signed_by_issuer && ( deadline_passed || issuer_is_current_owner ) && mint_valid

  let has_bid: Bool = datum.highest_bid > 0

  if has_bid {
    expect Some(output_to_bidder) =
      list.at(transaction.outputs, output_to_bidder_index)

    let expected_assets_to_bidder: Value =
      assets.from_asset(
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        datum.highest_bid,
      )

    let bidder_address =
      from_verification_key(datum.highest_bidder_pub_key_hash)

    let output_to_bidder_address_correct: Bool =
      bidder_address == output_to_bidder.address

    let assets_to_bidder_valid =
      match(output_to_bidder.value, expected_assets_to_bidder, >=)

    output_to_bidder_address_correct && assets_to_bidder_valid
  } else {
    True
  }
}

fn place_bid_valid(
  datum: OptionDatum,
  transaction: Transaction,
  output_to_script_index: Int,
  output_to_bidder_index: Int,
) {
  let all_inputs_from_script = get_validators_inputs(transaction)
  let only_one_validator_input: Bool = list.length(all_inputs_from_script) == 1

  expect Some(input_from_validator) = list.head(all_inputs_from_script)

  expect Some(output_back_to_script) =
    list.at(transaction.outputs, output_to_script_index)
  expect InlineDatum(output_datum) = output_back_to_script.datum
  expect output_datum_typed: OptionDatum = output_datum

  let address_valid: Bool =
    output_back_to_script.address == input_from_validator.output.address

  let expected_assets_sent_back =
    assets.from_asset(
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
      datum.from_asset_amount,
    )
      |> assets.add(
          datum.stable_asset.policy_id,
          datum.stable_asset.asset_name,
          output_datum_typed.highest_bid,
        )
      |> assets.add(datum.minted_asset.policy_id, datum.minted_asset.asset_name, 1)

  let assets_sent_back_valid =
    match(output_back_to_script.value, expected_assets_sent_back, >=)

  let deadline_not_passed: Bool =
    utils.get_lower_bound(transaction.validity_range) < datum.deadline

  let is_for_sale: Bool = datum.sell_stable_asset_amount > 0

  let expected_datum =
    OptionDatum {
      issuer_pub_key_hash: datum.issuer_pub_key_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_pub_key_hash: datum.current_owner_pub_key_hash,
      current_owner_bech32_address: datum.current_owner_bech32_address,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      stable_asset: datum.stable_asset,
      sell_stable_asset_amount: datum.sell_stable_asset_amount,
      highest_bid: output_datum_typed.highest_bid,
      highest_bidder_pub_key_hash: output_datum_typed.highest_bidder_pub_key_hash,
      highest_bidder_address: output_datum_typed.highest_bidder_address,
      deadline: datum.deadline,
      commission: datum.commission,
      minted_asset: datum.minted_asset,
    }

  expect
    is_for_sale && deadline_not_passed && only_one_validator_input && assets_sent_back_valid && expected_datum == output_datum_typed && address_valid

  let has_bid: Bool = datum.highest_bid > 0

  if has_bid {
    expect Some(output_to_bidder) =
      list.at(transaction.outputs, output_to_bidder_index)

    let expected_assets_sent_to_bidder =
      assets.from_asset(
        datum.stable_asset.policy_id,
        datum.stable_asset.asset_name,
        datum.highest_bid,
      )

    let bid_higher_than_current: Bool =
      output_datum_typed.highest_bid > datum.highest_bid

    let assets_to_bidder_valid =
      match(output_to_bidder.value, expected_assets_sent_to_bidder, >=)

    bid_higher_than_current && assets_to_bidder_valid
  } else {
    True
  }
}

fn cancel_bid_valid(
  datum: OptionDatum,
  transaction: Transaction,
  output_to_validator_index: Int,
) {
  let all_inputs_from_script = get_validators_inputs(transaction)
  let only_one_validator_input: Bool = list.length(all_inputs_from_script) == 1
  expect Some(input_from_validator) = list.head(all_inputs_from_script)

  expect Some(output_to_validator) =
    list.at(transaction.outputs, output_to_validator_index)
  expect InlineDatum(output_datum) = output_to_validator.datum
  expect output_datum_typed: OptionDatum = output_datum

  let output_address_valid: Bool =
    output_to_validator.address == input_from_validator.output.address

  let expected_assets_send_back =
    assets.from_asset(
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
      datum.from_asset_amount,
    )
      |> assets.add(datum.minted_asset.policy_id, datum.minted_asset.asset_name, 1)

  let assets_send_back_valid =
    match(output_to_validator.value, expected_assets_send_back, >=)

  let expected_datum_value =
    OptionDatum {
      issuer_pub_key_hash: datum.issuer_pub_key_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_pub_key_hash: datum.current_owner_pub_key_hash,
      current_owner_bech32_address: datum.current_owner_bech32_address,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      stable_asset: datum.stable_asset,
      sell_stable_asset_amount: datum.sell_stable_asset_amount,
      highest_bid: 0,
      highest_bidder_pub_key_hash: "",
      highest_bidder_address: "",
      deadline: datum.deadline,
      commission: datum.commission,
      minted_asset: datum.minted_asset,
    }

  let datum_value_not_corrupted: Bool =
    expected_datum_value == output_datum_typed

  let signed_by_bidder: Bool =
    list.has(transaction.extra_signatories, datum.highest_bidder_pub_key_hash)

  datum_value_not_corrupted && signed_by_bidder && assets_send_back_valid && only_one_validator_input && output_address_valid
}

fn accept_bid_valid(
  datum: OptionDatum,
  transaction: Transaction,
  output_to_issuer_index: Int,
  output_to_validator_index: Int,
) {
  let all_inputs_from_script = get_validators_inputs(transaction)
  let only_one_validator_input: Bool = list.length(all_inputs_from_script) == 1

  expect Some(input_from_validator) = list.head(all_inputs_from_script)

  expect Some(output_to_validator) =
    list.at(transaction.outputs, output_to_validator_index)
  expect InlineDatum(output_datum) = output_to_validator.datum
  expect output_datum_typed: OptionDatum = output_datum

  let output_address_valid: Bool =
    output_to_validator.address == input_from_validator.output.address

  let signed_by_holder: Bool =
    list.has(transaction.extra_signatories, datum.current_owner_pub_key_hash)

  let expected_datum =
    OptionDatum {
      issuer_pub_key_hash: datum.issuer_pub_key_hash,
      issuer_bech32_address: datum.issuer_bech32_address,
      current_owner_pub_key_hash: output_datum_typed.current_owner_pub_key_hash,
      current_owner_bech32_address: output_datum_typed.current_owner_bech32_address,
      from_asset: datum.from_asset,
      from_asset_amount: datum.from_asset_amount,
      to_asset: datum.to_asset,
      to_asset_amount: datum.to_asset_amount,
      stable_asset: datum.stable_asset,
      sell_stable_asset_amount: 0,
      highest_bid: 0,
      highest_bidder_pub_key_hash: "",
      highest_bidder_address: "",
      deadline: datum.deadline,
      commission: datum.commission,
      minted_asset: datum.minted_asset,
    }

  let datum_value_not_corrupted: Bool = expected_datum == output_datum_typed

  let expected_assets_sent_back =
    assets.from_asset(
      datum.from_asset.policy_id,
      datum.from_asset.asset_name,
      datum.from_asset_amount,
    )
      |> assets.add(datum.minted_asset.policy_id, datum.minted_asset.asset_name, 1)

  let assets_sent_back_valid: Bool =
    match(output_to_validator.value, expected_assets_sent_back, >=)

  expect Some(output_to_issuer) =
    list.at(transaction.outputs, output_to_issuer_index)

  let issuer_address = from_verification_key(datum.issuer_pub_key_hash)

  expect issuer_address == output_to_issuer.address

  let expected_commission_amount: Int =
    datum.sell_stable_asset_amount * datum.commission / 100

  let expected_assets_to_issuer =
    assets.from_asset(
      datum.stable_asset.policy_id,
      datum.stable_asset.asset_name,
      expected_commission_amount,
    )

  let assets_to_issuer_valid =
    match(output_to_issuer.value, expected_assets_to_issuer, >=)

  datum_value_not_corrupted && signed_by_holder && only_one_validator_input && output_address_valid && assets_sent_back_valid && assets_to_issuer_valid
}

fn mint_valid(
  transaction: Transaction,
  policy_id: PolicyId,
  asset_name: AssetName,
  output_to_script_index: Int,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
) {
  let mint_valid = [(policy_id, asset_name, 1)] == flatten(transaction.mint)

  expect Some(output_to_script) =
    list.at(transaction.outputs, output_to_script_index)

  let output_script_hash = get_script_hash(output_to_script.address)

  let output_is_to_script: Bool = output_script_hash == policy_id

  expect InlineDatum(output_datum) = output_to_script.datum
  expect output_datum_typed: OptionDatum = output_datum

  let expected_assets_locked =
    assets.from_asset(policy_id, asset_name, 1)
      |> assets.add(
          output_datum_typed.from_asset.policy_id,
          output_datum_typed.from_asset.asset_name,
          output_datum_typed.from_asset_amount,
        )

  let assets_locked_valid =
    match(output_to_script.value, expected_assets_locked, >=)

  let deadline_not_passed: Bool =
    utils.get_lower_bound(transaction.validity_range) < output_datum_typed.deadline

  let stable_asset_valid =
    output_datum_typed.stable_asset.asset_name == stable_asset_name && output_datum_typed.stable_asset.policy_id == stable_policy_id

  mint_valid && output_is_to_script && assets_locked_valid && deadline_not_passed && stable_asset_valid
}

fn burn_valid(
  transaction: Transaction,
  policy_id: PolicyId,
  asset_name: AssetName,
) {
  [(policy_id, asset_name, -1)] == flatten(transaction.mint)
}

validator options(
  _underlying_policy_id: PolicyId,
  _underlying_asset_name: AssetName,
  stable_policy_id: PolicyId,
  stable_asset_name: AssetName,
  asset_name: AssetName,
) {
  spend(
    datum: Option<OptionDatum>,
    redeemer: Redeemer,
    _: Data,
    transaction: Transaction,
  ) {
    expect Some(datum) = datum

    when redeemer is {
      BuyOption(
        output_to_script_index,
        output_to_owner_index,
        output_to_issuer_index,
        output_to_bidder_index,
      ) ->
        buy_option_valid(
          datum,
          transaction,
          output_to_script_index,
          output_to_owner_index,
          output_to_issuer_index,
          output_to_bidder_index,
        )

      ChangeSellPrice(output_to_script_index, output_to_bidder_index) ->
        change_sell_price_valid(
          datum,
          transaction,
          output_to_script_index,
          output_to_bidder_index,
        )

      ExerciseOption(output_to_script_index, output_to_bidder_index) ->
        exercise_option_valid(
          datum,
          transaction,
          output_to_script_index,
          output_to_bidder_index,
        )

      CancelOption(output_to_bidder_index) ->
        issuer_cancel_option_valid(datum, transaction, output_to_bidder_index)

      PlaceBid(output_to_script_index, output_to_bidder_index) ->
        place_bid_valid(
          datum,
          transaction,
          output_to_script_index,
          output_to_bidder_index,
        )

      CancelBid(output_to_script_index) ->
        cancel_bid_valid(datum, transaction, output_to_script_index)

      AcceptBid(output_to_script_index, output_to_issuer_index) ->
        accept_bid_valid(
          datum,
          transaction,
          output_to_script_index,
          output_to_issuer_index,
        )
    }
  }

  mint(rdmr: MintRedeemer, policy_id: PolicyId, transaction: Transaction) {
    when rdmr is {
      Mint(output_to_script_index) ->
        mint_valid(
          transaction,
          policy_id,
          asset_name,
          output_to_script_index,
          stable_policy_id,
          stable_asset_name,
        )
      Burn -> burn_valid(transaction, policy_id, asset_name)
    }
  }

  else(_) {
    fail
  }
}

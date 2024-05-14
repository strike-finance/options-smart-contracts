use aiken/list
use aiken/transaction.{Output, ScriptContext, Spend}
use aiken/transaction/credential.{Address, from_verification_key}
use aiken/transaction/value.{lovelace_of}
use types.{LovelaceAmount, OptionDatum}
use utils.{get_lovelace_to_address}

type LoanRedeemer {
  SellOption
  RealizeOption
}

type Redeemer {
  action: LoanRedeemer,
}

// sell_amount paid to current owner
// deadline has not passed
// percentage paid to original owner 
// least ada per sell to issuer is 2 ada
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
    amount_to_issuer > datum.sell_lovelace_amount * datum.sell_percent || amount_to_current_owner > 2000000

  expect Spend(my_output_reference) = ctx.purpose

  expect Some(input_from_script) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  let lovelace_amount_locked: Int = lovelace_of(input_from_script.output.value)

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

  amount_to_current_owner_valid && deadline_not_passed && amount_to_issuer_valid && only_one_validator_input && only_one_validtaor_output && lovelace_amount_same
}

// deadline not passed, 
// get lovelace locked in this utxo, send  usdm to original owner 
// or deadline passed and original owner signed transaction
fn realize_option_valid() {
  True
}

validator {
  fn spend(datum: OptionDatum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    when redeemer.action is {
      SellOption -> sell_option_valid(datum, ctx)

      RealizeOption -> realize_option_valid()
    }
  }
}

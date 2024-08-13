use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, WithdrawFrom, find_script_outputs,
}
use aiken/transaction/credential.{Address,
  Inline, ScriptCredential, from_script}
use aiken/transaction/value.{PolicyId, quantity_of}
use types.{OptionDatum}
use utils.{get_address_outputs, get_inputs_from_script}

type RedeemrAction {
  SellOption
  SellNewOption
  BuyOption
}

type Redeemer {
  action: RedeemrAction,
}

type AssetClass {
  policy_id: PolicyId,
  asset_name: ByteArray,
}

validator(options_validator_hash: ByteArray) {
  fn withdraw(redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    expect ScriptContext { transaction: _tx, purpose: WithdrawFrom(stake_cred) } =
      ctx
    expect Inline(ScriptCredential(pool_validator_hash)) = stake_cred

    when redeemer.action is {
      SellOption -> {
        let inputs_from_options_validator =
          get_inputs_from_script(ctx.transaction.inputs, options_validator_hash)

        expect Some(input_from_options_validator) =
          list.at(inputs_from_options_validator, 0)

        expect InlineDatum(input_from_options_validator_datum) =
          input_from_options_validator.output.datum
        expect input_from_options_validator_datum_typed: OptionDatum =
          input_from_options_validator_datum

        let only_one_input_from_options_validator =
          list.length(inputs_from_options_validator) == 1

        let validator_inputs: List<Input> =
          get_inputs_from_script(ctx.transaction.inputs, pool_validator_hash)

        expect Some(validator_input) = list.at(validator_inputs, 0)

        let outputs_back_to_validator: List<Output> =
          get_address_outputs(ctx, validator_input.output.address)

        let from_asset_back_to_validator =
          list.any(
            outputs_back_to_validator,
            fn(output) {
              quantity_of(
                output.value,
                input_from_options_validator_datum_typed.from_asset.policy_id,
                input_from_options_validator_datum_typed.from_asset.asset_name,
              ) >= input_from_options_validator_datum_typed.from_asset_amount
            },
          )

        only_one_input_from_options_validator && from_asset_back_to_validator
      }

      BuyOption -> {
        let outputs_to_options_script: List<Output> =
          find_script_outputs(ctx.transaction.outputs, options_validator_hash)
        expect Some(output_to_options_script) =
          list.at(outputs_to_options_script, 0)

        expect InlineDatum(output_datum) = output_to_options_script.datum
        expect output_datum_typed: OptionDatum = output_datum

        let only_one_output_to_script: Bool =
          list.length(outputs_to_options_script) == 1

        let pool_address: Address = output_to_options_script.address

        let pool_address_in_datum_valid =
          from_script(output_datum_typed.pool_script_hash) == pool_address

        let must_be_signed_by_owner =
          list.has(
            ctx.transaction.extra_signatories,
            output_datum_typed.owner_address_hash,
          )

        only_one_output_to_script && must_be_signed_by_owner && pool_address_in_datum_valid
      }

      SellNewOption -> {
        let outputs_to_options_script: List<Output> =
          find_script_outputs(ctx.transaction.outputs, options_validator_hash)
        expect Some(output_to_options_script) =
          list.at(outputs_to_options_script, 0)

        expect InlineDatum(output_datum) = output_to_options_script.datum
        expect output_datum_typed: OptionDatum = output_datum

        let must_be_signed_by_owner =
          list.has(
            ctx.transaction.extra_signatories,
            output_datum_typed.owner_address_hash,
          )

        must_be_signed_by_owner
      }
    }
  }
}

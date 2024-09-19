use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Address, Credential, Script}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
  find_script_outputs,
}
use types.{
  AddressHash, BuyOption, OptionDatum, WithdrawRedeemer, WithdrawSellOption,
}
use utils.{get_address_outputs, get_inputs_from_script}

type AssetClass {
  policy_id: PolicyId,
  asset_name: ByteArray,
}

validator pool(
  options_validator_hash: ByteArray,
  validated_signature: AddressHash,
) {
  spend(_datum, _redeemer: Int, own_ref: OutputReference, self: Transaction) {
    expect Some(input) = find_input(self.inputs, own_ref)

    let withdrawals = self.withdrawals

    let own_withdrawal = input.output.address.payment_credential

    pairs.has_key(withdrawals, own_withdrawal)
  }

  withdraw(
    redeemer: WithdrawRedeemer,
    credential: Credential,
    transaction: Transaction,
  ) {
    expect Script(pool_validator_hash) = credential
    when redeemer is {
      BuyOption -> {
        trace @"BuyOption"
        let outputs_to_options_script: List<Output> =
          find_script_outputs(transaction.outputs, options_validator_hash)
        expect Some(output_to_options_script) =
          list.at(outputs_to_options_script, 0)
        expect InlineDatum(output_datum) = output_to_options_script.datum
        expect output_datum_typed: OptionDatum = output_datum
        let only_one_output_to_script: Bool =
          list.length(outputs_to_options_script) == 1
        let pool_address_in_datum_valid =
          output_datum_typed.pool_script_hash == pool_validator_hash
        let must_be_signed_by_owner =
          list.has(
            transaction.extra_signatories,
            output_datum_typed.owner_address_hash,
          )
        let signed_by_validated_signature =
          list.has(transaction.extra_signatories, validated_signature)
        signed_by_validated_signature && only_one_output_to_script && must_be_signed_by_owner && pool_address_in_datum_valid
      }

      WithdrawSellOption -> {
        let inputs_from_options_validator =
          get_inputs_from_script(transaction.inputs, options_validator_hash)
        expect Some(input_from_options_validator) =
          list.at(inputs_from_options_validator, 0)
        expect InlineDatum(input_from_options_validator_datum) =
          input_from_options_validator.output.datum
        expect input_from_options_validator_datum_typed: OptionDatum =
          input_from_options_validator_datum
        let only_one_input_from_options_validator =
          list.length(inputs_from_options_validator) == 1
        let validator_inputs: List<Input> =
          get_inputs_from_script(transaction.inputs, pool_validator_hash)
        expect Some(validator_input) = list.at(validator_inputs, 0)
        let outputs_back_to_validator: List<Output> =
          get_address_outputs(transaction, validator_input.output.address)
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
        let signed_by_validated_signature =
          list.has(transaction.extra_signatories, validated_signature)
        signed_by_validated_signature && only_one_input_from_options_validator && from_asset_back_to_validator
      }
    }
  }

  else(_) {
    fail
  }
}

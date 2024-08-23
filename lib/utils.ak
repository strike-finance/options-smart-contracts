use aiken/builtin
use aiken/interval.{Finite}
use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, ScriptContext, ValidityRange,
}
use aiken/transaction/credential.{
  Address, Credential, ScriptCredential, VerificationKeyCredential,
}
use aiken/transaction/value.{quantity_of}
use types.{AssetClass, PoolDatum}

pub fn get_validators_inputs(ctx: ScriptContext) -> List<Input> {
  list.filter(
    ctx.transaction.inputs,
    fn(input) { is_script_credential(input.output.address.payment_credential) },
  )
}

pub fn is_script_credential(credential: Credential) -> Bool {
  when credential is {
    ScriptCredential(_validator_hash) -> True
    _ -> False
  }
}

pub fn get_inputs_from_script(
  inputs: List<Input>,
  script_hash: ByteArray,
) -> List<Input> {
  inputs
    |> list.filter(
        fn(input) {
          when input.output.address.payment_credential is {
            ScriptCredential(addr_script_hash) ->
              script_hash == addr_script_hash
            VerificationKeyCredential(_) -> False
          }
        },
      )
}

pub fn get_address_outputs(ctx: ScriptContext, address: Address) -> List<Output> {
  list.filter(ctx.transaction.outputs, fn(output) { output.address == address })
}

pub fn get_lower_bound(range: ValidityRange) -> Int {
  expect Finite(lower_bound) = range.lower_bound.bound_type
  lower_bound
}

pub fn resolve_output_reference(
  inputs: List<Input>,
  output_ref: OutputReference,
) -> Output {
  expect [input, ..] = inputs

  if input.output_reference == output_ref {
    input.output
  } else {
    resolve_output_reference(builtin.tail_list(inputs), output_ref)
  }
}

pub fn total_outputs_to_pool_script(outputs: List<Output>) -> Int {
  list.reduce(
    outputs,
    0,
    fn(acc: Int, output: Output) {
      expect InlineDatum(output_datum) = output.datum
      expect output_datum_typed: PoolDatum = output_datum

      let value =
        quantity_of(
          output.value,
          output_datum_typed.from_asset.policy_id,
          output_datum_typed.from_asset.asset_name,
        )

      if value > 0 {
        acc + value
      } else {
        acc
      }
    },
  )
}

use aiken/interval.{Finite}
use aiken/list
use aiken/option
use aiken/transaction.{
  Input, Output, OutputReference, ScriptContext, ValidityRange,
}
use aiken/transaction/credential.{
  Address, Credential, Inline, ScriptCredential, VerificationKeyCredential,
}
use aiken/transaction/value.{AssetName, PolicyId, quantity_of}
use types.{ValidatorHash}

pub fn own_validator_script_address_hash(
  inputs: List<Input>,
  output_reference: OutputReference,
) -> Option<ValidatorHash> {
  inputs
    |> list.find(fn(input) { input.output_reference == output_reference })
    |> option.map(fn(v) { v.output })
    |> option.map(fn(v) { v.address })
    |> option.map(fn(v) { v.payment_credential })
    |> option.map(
        fn(v) {
          when v is {
            ScriptCredential(hash) -> Some(hash)
            _ -> None
          }
        },
      )
    |> option.flatten()
}

pub fn get_asset_to_address(
  outputs: List<Output>,
  address: Address,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  let output_to_address =
    list.find(
      outputs,
      fn(output) {
        output.address.payment_credential == address.payment_credential
      },
    )

  when output_to_address is {
    Some(output) -> quantity_of(output.value, policy_id, asset_name)
    None -> 0
  }
}

pub fn scripthash_address(scripthash: ByteArray, stake_hash: ByteArray) {
  Address {
    payment_credential: ScriptCredential(scripthash),
    stake_credential: Some(Inline(VerificationKeyCredential(stake_hash))),
  }
}

pub fn get_own_validator_address(
  ctx: ScriptContext,
  output_reference: OutputReference,
  stake_hash,
) -> Address {
  expect Some(validator_hash) =
    own_validator_script_address_hash(ctx.transaction.inputs, output_reference)
  scripthash_address(validator_hash, stake_hash)
}

pub fn get_lower_bound(range: ValidityRange) -> Int {
  expect Finite(lower_bound) = range.lower_bound.bound_type
  lower_bound
}

pub fn get_validators_inputs(ctx: ScriptContext) -> List<Input> {
  list.filter(
    ctx.transaction.inputs,
    fn(input) { is_script_credential(input.output.address.payment_credential) },
  )
}

pub fn get_address_output(ctx: ScriptContext, address: Address) -> List<Output> {
  list.filter(ctx.transaction.outputs, fn(output) { output.address == address })
}

pub fn is_script_credential(credential: Credential) -> Bool {
  when credential is {
    ScriptCredential(_validator_hash) -> True
    _ -> False
  }
}

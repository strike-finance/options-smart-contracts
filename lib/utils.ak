use aiken/interval.{Finite}
use aiken/list
use aiken/transaction.{Input, Output, ScriptContext, ValidityRange}
use aiken/transaction/credential.{Address, Credential, ScriptCredential}
use aiken/transaction/value.{AssetName, PolicyId, quantity_of}

pub fn get_asset_to_address(
  outputs: List<Output>,
  address: Address,
  policy_id: PolicyId,
  asset_name: AssetName,
) -> Int {
  expect Some(output_to_address) =
    list.find(
      outputs,
      fn(output) {
        output.address.payment_credential == address.payment_credential
      },
    )
  quantity_of(output_to_address.value, policy_id, asset_name)
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

pub fn get_validators_outputs(ctx: ScriptContext) -> List<Output> {
  list.filter(
    ctx.transaction.outputs,
    fn(output) { is_script_credential(output.address.payment_credential) },
  )
}

pub fn is_script_credential(credential: Credential) -> Bool {
  when credential is {
    ScriptCredential(_validator_hash) -> True
    _ -> False
  }
}

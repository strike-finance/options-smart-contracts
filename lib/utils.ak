use aiken/collection/list
use aiken/interval.{Finite}
use cardano/address.{Address, Credential, Script}
use cardano/assets.{AssetName, PolicyId, quantity_of}
use cardano/transaction.{Input, Output, Transaction, ValidityRange}

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

pub fn get_lower_bound(range: ValidityRange) -> Int {
  expect Finite(lower_bound) = range.lower_bound.bound_type
  lower_bound
}

pub fn get_validators_inputs(transaction: Transaction) -> List<Input> {
  list.filter(
    transaction.inputs,
    fn(input) { is_script_credential(input.output.address.payment_credential) },
  )
}

pub fn get_address_outputs(
  transaction: Transaction,
  address: Address,
) -> List<Output> {
  list.filter(transaction.outputs, fn(output) { output.address == address })
}

pub fn is_script_credential(credential: Credential) -> Bool {
  when credential is {
    Script(_validator_hash) -> True
    _ -> False
  }
}

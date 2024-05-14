use aiken/transaction.{ScriptContext}
use types.{OptionDatum}

type LoanRedeemer {
  SellOption
  RealizeOption
}

type Redeemer {
  action: LoanRedeemer,
}

// sell_amount paid to current owner
// current_owner hash updated
// current_owner signed transaction 
// deadline has not passed
// percentage paid to original owner 
fn sell_option_valid() {
  True
}

// get usdm locked in this utxo, send lovelace to original owner 
// or deadline passed and original owner signed transaction
fn realize_option_valid() {
  True
}

validator {
  fn spend(_datum: OptionDatum, redeemer: Redeemer, _ctx: ScriptContext) -> Bool {
    when redeemer.action is {
      SellOption -> sell_option_valid()

      RealizeOption -> realize_option_valid()
    }
  }
}

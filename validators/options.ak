use aiken/transaction.{ScriptContext}

validator {
  fn spend(_datum: Int, _redeemer: Int, _ctx: ScriptContext) -> Bool {
    True
  }
}

// use aiken/collection/list
// use aiken/collection/pairs
// use aiken/crypto.{Blake2b_224, Hash, Script}
// use aiken/transaction/value.{PolicyId}
// use cardano/transaction.{InlineDatum, ScriptContext}
// use types.{GenericData, OracleDatum, PriceData}

// /// Represents a map of key-value pairs for price-related data
// /// Represents different types of price data
// /// Represents the main oracle datum structure
// /// Type alias for validator hash
// pub type ValidatorHash =
//   Hash<Blake2b_224, Script>

// /// Retrieves the price from the PriceData
// ///
// /// @param price_data - The PriceData to extract the price from
// /// @return The price as an Int
// pub fn get_price(price_data: PriceData) -> Int {
//   when price_data is {
//     GenericData { price_map } ->
//       when pairs.get_first(price_map, 0) is {
//         Some(price) -> price
//         None -> fail @"Price not found"
//       }
//     _ -> fail @"Invalid PriceData variant"
//   }
// }

// pub fn get_price_from_policy(policy: PolicyId, ctx: ScriptContext) -> Int {
//   let charlie3_token_name = #"4f7261636c6546656564"
//   expect Some(charli3_utxo) =
//     list.find(
//       ctx.transaction.reference_inputs,
//       fn(input) {
//         value.quantity_of(input.output.value, policy, charlie3_token_name) == 1
//       },
//     )

//   expect InlineDatum(oracle_datum) = charli3_utxo.output.datum
//   expect oracle_datum_typed: PriceData = oracle_datum

//   let price = get_price(oracle_datum_typed)
//   price
// }

// /// Retrieves the timestamp from the PriceData
// ///
// /// @param price_data - The PriceData to extract the timestamp from
// /// @return The timestamp as an Int
// pub fn get_timestamp(price_data: PriceData) -> Int {
//   when price_data is {
//     GenericData { price_map } ->
//       when pairs.get_first(price_map, 1) is {
//         Some(timestamp) -> timestamp
//         None -> fail @"Timestamp not found"
//       }
//     _ -> fail @"Invalid PriceData variant"
//   }
// }

// /// Retrieves the expiry from the PriceData
// ///
// /// @param price_data - The PriceData to extract the expiry from
// /// @return The expiry as an Int
// pub fn get_expiry(price_data: PriceData) -> Int {
//   when price_data is {
//     GenericData { price_map } ->
//       when pairs.get_first(price_map, 2) is {
//         Some(expiry) -> expiry
//         None -> fail @"Expiry not found"
//       }
//     _ -> fail @"Invalid PriceData variant"
//   }
// }

// /// Checks if the oracle data is valid (not expired)
// ///
// /// @param oracle_datum - The OracleDatum to check
// /// @param current_time - The current time to compare against
// /// @return True if the oracle is valid, False otherwise
// pub fn is_oracle_valid(oracle_datum: OracleDatum, current_time: Int) -> Bool {
//   current_time <= get_expiry(oracle_datum.price_data)
// }

// /// Retrieves the price from the OracleDatum
// ///
// /// @param oracle_datum - The OracleDatum to extract the price from
// /// @return The price as an Int
// pub fn get_oracle_price(oracle_datum: OracleDatum) -> Int {
//   get_price(oracle_datum.price_data)
// }

// /// Retrieves the timestamp from the OracleDatum
// ///
// /// @param oracle_datum - The OracleDatum to extract the timestamp from
// /// @return The timestamp as an Int
// pub fn get_oracle_timestamp(oracle_datum: OracleDatum) -> Int {
//   get_timestamp(oracle_datum.price_data)
// }

// /// Creates a new OracleDatum with the given price, timestamp, and expiry
// ///
// /// @param price - The price to set
// /// @param timestamp - The timestamp to set
// /// @param expiry - The expiry to set
// /// @return A new OracleDatum
// pub fn create_oracle_datum(
//   price: Int,
//   timestamp: Int,
//   expiry: Int,
// ) -> OracleDatum {
//   OracleDatum {
//     price_data: GenericData {
//       price_map: [Pair(0, price), Pair(1, timestamp), Pair(2, expiry)],
//     },
//   }
// }

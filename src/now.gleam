import gleam/io
import mist
import gleam/http/response
import gleam/bit_builder
import gleam/erlang/process
import gleam/erlang/os
import gleam/result
import gleam/int
import routes

pub fn main() {
  let port = load_port()

  let assert Ok(_) =
    mist.run_service(port, routes.handle_request, max_body_limit: 4000)

  io.println("Listening on http://localhost:" <> int.to_string(port))

  process.sleep_forever()
}

fn load_port() -> Int {
  os.get_env("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3050)
}

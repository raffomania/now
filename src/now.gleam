import gleam/io
import mist
import gleam/erlang/process
import gleam/erlang/os
import gleam/result
import gleam/int
import routes
import database
import snag_extra
import snag

pub fn main() -> snag.Result(Nil) {
  use <- snag_extra.print_if_error()
  let port = load_port()
  use db <- database.open()
  let assert Ok(_) = database.migrate_schema(db)

  let assert Ok(_) =
    mist.run_service(port, routes.handle_request, max_body_limit: 4000)

  io.println("Listening on http://localhost:" <> int.to_string(port))

  process.sleep_forever()

  Ok(Nil)
}

fn load_port() -> Int {
  os.get_env("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3050)
}

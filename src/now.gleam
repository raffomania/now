import gleam/io
import mist
import gleam/http/response
import gleam/bit_builder
import gleam/erlang/process

pub fn main() {
  let assert Ok(_) =
    mist.run_service(
      3050,
      fn(_req) {
        response.new(200)
        |> response.set_header("content-type", "text/html; charset=utf-8")
        |> response.set_body(bit_builder.from_string("tets"))
      },
      max_body_limit: 4000,
    )

  io.println("http://localhost:3050")

  process.sleep_forever()
}

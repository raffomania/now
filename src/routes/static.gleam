import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/bit_builder.{BitBuilder}
import gleam/erlang/file
import gleam/result
import gleam/string

pub fn handle(request: Request(in)) -> Response(BitBuilder) {
  let path =
    string.concat([
      "priv",
      string.replace(in: request.path, each: "..", with: ""),
    ])

  let file_contents =
    path
    |> file.read_bits
    |> result.nil_error
    |> result.map(bit_builder.from_bit_string)

  case file_contents {
    Ok(bits) -> Response(200, [], bits)
    Error(_) -> Response(404, [], bit_builder.new())
  }
}

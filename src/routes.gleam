import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/bit_builder.{BitBuilder}
import gleam/io

pub fn handle_request(req: Request(BitString)) -> Response(BitBuilder) {
  io.debug(request.path_segments(req))
  case request.path_segments(req) {
    _ -> home(req)
  }
}

fn home(_req: Request(_)) -> Response(_) {
  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(bit_builder.from_string("tets"))
}

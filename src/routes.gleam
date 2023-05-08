import gleam/http/response.{Response}
import gleam/http
import gleam/uri
import gleam/http/request.{Request}
import gleam/bit_builder.{BitBuilder}
import gleam/io
import gleam/bit_string
import gleam/string_builder.{StringBuilder}
import views/home
import nakai

fn html_header(res: Response(_)) -> Response(_) {
  response.set_header(res, "content-type", "text/html; charset=utf-8")
}

pub fn handle_request(req: Request(BitString)) -> Response(BitBuilder) {
  let assert Ok(string_body) = bit_string.to_string(req.body)
  let req = request.set_body(req, string_body)
  let string_response = case request.path_segments(req) {
    [] -> home(req)
    ["entries"] -> entries(req)
    _ -> response.new(404)
  }

  string_response
  |> response.map(bit_builder.from_string)
}

fn entries(req: Request(String)) -> Response(String) {
  case req.method {
    _ -> create_entry(req)
  }
}

fn home(_req: Request(_)) -> Response(String) {
  let body =
    home.view()
    |> nakai.to_string()
  response.new(200)
  |> html_header()
  |> response.set_body(body)
}

fn create_entry(request: Request(String)) -> Response(String) {
  let body = uri.parse_query(request.body)
  io.debug("body:")
  io.debug(body)
  response.new(200)
}

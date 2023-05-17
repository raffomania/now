import gleam/http/response.{Response}
import gleam/uri
import gleam/http/request.{Request}
import gleam/bit_builder.{BitBuilder}
import database/entries
import database
import gleam/io
import gleam/bit_string
import views/home
import nakai
import routes/static

fn html_header(res: Response(_)) -> Response(_) {
  response.set_header(res, "content-type", "text/html; charset=utf-8")
}

pub fn handle_request(req: Request(BitString)) -> Response(BitBuilder) {
  let assert Ok(string_body) = bit_string.to_string(req.body)
  let req = request.set_body(req, string_body)
  let string_response = case request.path_segments(req) {
    ["static", ..] -> static.handle(req)
    segments ->
      case segments {
        [] -> home(req)
        ["entries"] -> entries(req)
        _ -> response.new(404)
      }
      |> response.map(bit_builder.from_string)
  }

  string_response
}

fn entries(req: Request(String)) -> Response(String) {
  create_entry(req)
}

fn home(_req: Request(_)) -> Response(String) {
  use db <- database.open()
  let assert Ok(entries) = entries.list(db)
  io.debug(entries)
  let body =
    home.view(entries)
    |> nakai.to_string()
  response.new(200)
  |> html_header()
  |> response.set_body(body)
}

fn create_entry(request: Request(String)) -> Response(String) {
  let assert Ok(body) = uri.parse_query(request.body)
  let assert Ok(create) = entries.create_from_body(body)
  use db <- database.open()
  let assert Ok(_id) = entries.insert(create, db)

  response.redirect("/")
}

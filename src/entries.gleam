import gleam/http/response.{Response}
import gleam/io
import gleam/string
import snag
import snag_extra
import sqlight
import birl/time
import gleam/uri
import gleam/regex
import gleam/list
import projects
import gleam/result
import gleam/http/request.{Request}
import database
import entries/db_entries

pub fn handle(req: Request(String)) -> Response(String) {
  create_entry(req)
}

fn create_entry(request: Request(String)) -> Response(String) {
  let assert Ok(body) = uri.parse_query(request.body)
  use db <- database.open()
  let assert Ok(create) = create_from_body(body, db)
  let assert Ok(_id) = db_entries.insert(create, db)

  response.redirect("/")
}

fn create_from_body(
  body: List(#(String, String)),
  db: sqlight.Connection,
) -> snag.Result(db_entries.Create) {
  use text <- snag_extra.try(
    list.key_find(body, "text"),
    "Missing key 'name' in body",
  )

  let #(name, date_time) = split_name_and_date(text)

  let maybe_project = case projects.find_by_fuzzy_name(name, db) {
    Ok(project) -> Ok(project)
    Error(_) -> projects.insert(projects.Create(name: name), db)
  }
  use project <- result.try(maybe_project)

  let date_time =
    date_time
    |> result.unwrap(time.now())
  Ok(db_entries.Create(project_id: project.id, datetime: date_time))
}

fn split_name_and_date(text: String) -> #(String, Result(time.DateTime, Nil)) {
  let date_text = find_date_text(text)
  let date = result.try(date_text, time.from_iso8601)
  // If the date can be parsed, remove its text from the original input to get
  // the name.
  let name = case #(date, date_text) {
    #(Ok(_), Ok(date_text)) ->
      string.replace(in: text, each: date_text, with: "")
      |> string.trim
    #(Error(_), _) -> text
  }

  #(name, date)
}

fn find_date_text(text: String) -> Result(String, Nil) {
  let pattern =
    regex.from_string("@[0-9]{4}-[0-9]{2}-[0-9]{2}")
    |> result.nil_error()
  use pattern <- result.try(pattern)

  regex.scan(pattern, text)
  |> list.first
  |> result.map(fn(match) { match.content })
}

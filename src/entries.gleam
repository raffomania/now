import gleam/http/response.{Response}
import snag
import snag_extra
import sqlight
import birl/time
import gleam/uri
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
  use name <- snag_extra.try(
    list.key_find(body, "name"),
    "Missing key 'name' in body",
  )
  let maybe_project = case projects.find_by_fuzzy_name(name, db) {
    Ok(project) -> Ok(project)
    Error(_) -> projects.insert(projects.Create(name: name), db)
  }
  use project <- result.try(maybe_project)

  let datetime = time.now()
  Ok(db_entries.Create(project_id: project.id, datetime: datetime))
}

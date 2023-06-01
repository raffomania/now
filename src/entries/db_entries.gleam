import sqlight
import gleam/dynamic
import gleam/result
import gleam/list
import snag
import birl/time
import database
import projects
import gleam/option

pub type Entry {
  Entry(
    id: Int,
    project_id: Int,
    datetime: time.DateTime,
    note: option.Option(String),
  )
}

pub type EntryWithProject {
  EntryWithProject(entry: Entry, project: projects.Project)
}

pub type Create {
  Create(project_id: Int, datetime: time.DateTime)
}

fn entry_from_row() {
  dynamic.decode4(
    Entry,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.int),
    dynamic.element(2, database.decode_unix_timestamp),
    dynamic.element(3, dynamic.optional(dynamic.string)),
  )
}

pub fn insert(entry: Create, db: sqlight.Connection) -> snag.Result(Int) {
  "
    insert into entries
      (datetime, project_id)
    values
      ($1, $2)
    returning
      id
  "
  |> sqlight.query(
    on: db,
    with: [
      sqlight.int(time.to_unix(entry.datetime)),
      sqlight.int(entry.project_id),
    ],
    expecting: dynamic.element(0, dynamic.int),
  )
  |> database.result_to_snag()
  |> result.then(fn(rows) {
    list.first(rows)
    |> result.replace_error(snag.new("Database response was empty"))
  })
}

fn decode_entry_with_project() {
  dynamic.decode2(EntryWithProject, entry_from_row(), projects.decode_row(4))
}

pub fn list(db: sqlight.Connection) -> snag.Result(List(EntryWithProject)) {
  "select entries.*, projects.* from entries join projects on projects.id = entries.project_id"
  |> sqlight.query(on: db, with: [], expecting: decode_entry_with_project())
  |> database.result_to_snag()
}

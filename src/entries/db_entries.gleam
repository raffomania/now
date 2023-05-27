import sqlight
import gleam/dynamic
import gleam/result
import gleam/list
import snag
import birl/time
import database
import gleam/option

pub type Entry {
  Entry(
    id: Int,
    project_id: Int,
    datetime: time.DateTime,
    note: option.Option(String),
  )
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
    dynamic.optional(dynamic.element(3, dynamic.string)),
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
  |> result.map_error(fn(e) {
    snag.new("Query failed")
    |> snag.layer(e.message)
  })
  |> result.then(fn(rows) {
    list.first(rows)
    |> result.replace_error(snag.new("Database response was empty"))
  })
}

pub fn list(db: sqlight.Connection) -> Result(List(Entry), Nil) {
  "select * from entries"
  |> sqlight.query(on: db, with: [], expecting: entry_from_row())
  |> result.replace_error(Nil)
}

import sqlight
import gleam/dynamic
import gleam/result
import gleam/list
import gleam/map
import gleam/io
import snag

pub type Create {
  Create(name: String)
}

pub type Entry {
  Entry(id: Int, name: String)
}

pub fn create_from_body(
  body: List(#(String, String)),
) -> Result(Create, dynamic.DecodeErrors) {
  map.from_list(body)
  |> dynamic.from
  |> dynamic.decode1(Create, dynamic.field("name", dynamic.string))
}

fn entry_from_row() {
  dynamic.decode2(
    Entry,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
  )
}

pub fn insert(entry: Create, db: sqlight.Connection) -> snag.Result(Int) {
  "
    insert into entries
      (name)
    values
      ($1)
    returning
      id
  "
  |> sqlight.query(
    on: db,
    with: [sqlight.text(entry.name)],
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

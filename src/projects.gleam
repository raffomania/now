import sqlight
import gleam/io
import gleam/string
import snag
import gleam/dynamic
import gleam/result
import gleam/list

pub type Id =
  Int

pub type Project {
  Project(id: Id, name: String)
}

pub type Create {
  Create(name: String)
}

pub fn insert(create: Create, db: sqlight.Connection) -> snag.Result(Project) {
  "
    insert into projects
      (name)
    values
      ($1)
    returning
      *
  "
  |> sqlight.query(
    on: db,
    with: [sqlight.text(create.name)],
    expecting: decode_row(0),
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

pub fn decode_row(offset: Int) {
  dynamic.decode2(
    Project,
    dynamic.element(0 + offset, dynamic.int),
    dynamic.element(1 + offset, dynamic.string),
  )
}

pub fn find_by_fuzzy_name(
  name: String,
  db: sqlight.Connection,
) -> Result(Project, Nil) {
  "
    select * from projects 
    where lower(name) = lower($1) 
    limit 1
  "
  |> sqlight.query(on: db, with: [sqlight.text(name)], expecting: decode_row(0))
  |> result.replace_error(Nil)
  |> result.then(list.first)
}

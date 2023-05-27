import sqlight
import snag
import gleam/dynamic
import gleam/result
import gleam/list

pub type Project {
  Project(id: Int, name: String)
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
    expecting: decode_row(),
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

fn decode_row() {
  dynamic.decode2(
    Project,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
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
  |> sqlight.query(on: db, with: [sqlight.text(name)], expecting: decode_row())
  |> result.replace_error(Nil)
  |> result.then(list.first)
}

import sqlight
import snag
import gleam/dynamic
import gleam/result
import birl/time

pub fn open(next: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection("now.sqlite")
  let assert Ok(_) =
    "pragma foreign_keys = on;"
    |> sqlight.exec(db)
  next(db)
}

pub fn migrate_schema(db: sqlight.Connection) {
  "
    create table if not exists entries (
      id integer 
        primary key 
        autoincrement 
        not null,
      project_id integer 
        not null 
        references projects(id),
      datetime integer
        not null,
      note text
    ) strict;

    create table if not exists projects (
      id integer primary key autoincrement not null,
      name text
        not null
        constraint not_empty check (name != '')
    ) strict;
    "
  |> sqlight.exec(db)
}

pub fn decode_unix_timestamp(
  data: dynamic.Dynamic,
) -> Result(time.DateTime, List(dynamic.DecodeError)) {
  dynamic.int(data)
  |> result.map(time.from_unix)
}

pub fn result_to_snag(result: Result(res, sqlight.Error)) -> snag.Result(res) {
  result.map_error(result, fn(error) { snag.new(error.message) })
}

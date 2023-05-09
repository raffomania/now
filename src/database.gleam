import sqlight

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
        id integer primary key autoincrement not null,
        name text
            not null
            constraint not_empty check (name != '')
    );
    "
  |> sqlight.exec(db)
}

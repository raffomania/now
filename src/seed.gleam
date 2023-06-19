import entries/db_entries
import birl/time
import birl/duration
import gleam/list
import gleam/io
import gleam/result
import sqlight
import projects
import snag
import database
import snag_extra

pub fn main() {
  use <- snag_extra.print_if_error()
  use db <- database.open()

  let assert Ok(_) = database.migrate_schema(db)

  let entries_exist =
    db_entries.list(db)
    |> result.map(list.is_empty)

  use entries_exist <- result.try(entries_exist)
  case entries_exist {
    True -> insert_test_data(db)
    False -> {
      io.println("Database not empty, skipping seeding")
      Ok(Nil)
    }
  }
}

fn insert_test_data(db: sqlight.Connection) -> snag.Result(Nil) {
  io.println("writing seed data...")
  let projects =
    test_data_projects()
    |> list.map(projects.insert(_, db))
    |> result.all()
  use projects <- result.try(projects)

  test_data_entries(projects)
  |> list.map(db_entries.insert(_, db))
  |> result.all()
  |> result.replace(Nil)
}

fn test_data_projects() -> List(projects.Create) {
  [projects.Create("now"), projects.Create("knakk")]
}

fn test_data_entries(
  projects: List(projects.Project),
) -> List(db_entries.Create) {
  let now = time.now()
  let assert Ok(project_now) =
    list.first(projects)
    |> result.map(fn(proj) { proj.id })
  let assert Ok(project_knakk) =
    list.at(projects, 1)
    |> result.map(fn(proj) { proj.id })

  [
    db_entries.Create(datetime: now, project_id: project_now),
    db_entries.Create(
      datetime: time.subtract(now, duration.days(2)),
      project_id: project_knakk,
    ),
    db_entries.Create(
      datetime: time.subtract(now, duration.days(3)),
      project_id: project_now,
    ),
    db_entries.Create(
      datetime: time.subtract(now, duration.days(6)),
      project_id: project_knakk,
    ),
    db_entries.Create(
      datetime: time.subtract(now, duration.days(8)),
      project_id: project_now,
    ),
  ]
}

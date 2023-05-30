import entries/db_entries
import birl/time
import birl/duration
import gleam/list
import gleam/io
import gleam/result
import sqlight
import projects
import snag

pub fn seed(db: sqlight.Connection) -> snag.Result(Nil) {
  let entries_exist =
    db_entries.list(db)
    |> result.map(list.is_empty)

  use entries_exist <- result.try(entries_exist)
  case entries_exist {
    True -> insert_test_data(db)
    False -> Ok(Nil)
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
  [projects.Create("now")]
}

fn test_data_entries(
  projects: List(projects.Project),
) -> List(db_entries.Create) {
  let month = duration.months(2)
  let now = time.now()
  let project_id =
    list.first(projects)
    |> result.map(fn(proj) { proj.id })
    |> result.unwrap(0)
  [
    db_entries.Create(datetime: now, project_id: project_id),
    db_entries.Create(
      datetime: time.subtract(now, month),
      project_id: project_id,
    ),
  ]
}

import gleam/int
import entries/db_entries
import birl/time
import gleam/io
import gleam/list
import gleam/map
import gleam/option
import projects

pub type Line {
  Line(name: String, start: Int, end: Int, indent: Int)
}

pub type Timeline =
  map.Map(projects.Id, Line)

pub fn new() -> Timeline {
  map.new()
}

pub fn add_entry(timeline: Timeline, new_entry: db_entries.Entry) -> Timeline {
  map.update(
    timeline,
    new_entry.project_id,
    fn(maybe_line) {
      let line = case maybe_line {
        option.Some(line) -> add_entry_to_line(line, new_entry)
        option.None ->
          Line(
            name: int.to_string(new_entry.project_id),
            start: date_to_grid_position(new_entry.datetime),
            end: date_to_grid_position(new_entry.datetime),
            indent: 0,
          )
      }

      let largest_overlapping_indent =
        map.values(timeline)
        |> list.filter(overlapping(_, line))
        |> list.filter(fn(other) { other.name != line.name })
        |> list.map(fn(line) { line.indent })
        |> list.fold(-1, int.max)

      Line(..line, indent: largest_overlapping_indent + 1)
    },
  )
}

pub fn overlapping(a: Line, b: Line) -> Bool {
  a.start <= b.end && a.end >= b.start
}

fn date_to_grid_position(date_time: time.DateTime) -> Int {
  let to_bucket = fn(date_time: time.DateTime) -> Int {
    let time.Date(year, month, _day) = time.get_date(date_time)
    year * 12 + month
  }

  let now_month = to_bucket(time.now())
  let date_month = to_bucket(date_time)

  now_month - date_month
}

fn add_entry_to_line(line: Line, new_entry: db_entries.Entry) -> Line {
  let new_start = int.min(line.start, date_to_grid_position(new_entry.datetime))
  let new_end = int.max(line.end, date_to_grid_position(new_entry.datetime))
  Line(..line, start: new_start, end: new_end)
}

pub type Label {
  Label(names: List(String), position: Int, indent: Int)
}

pub fn labels(timeline: Timeline) -> List(Label) {
  timeline
  |> map.values()
  |> list.group(fn(line) { line.start })
  |> map.map_values(fn(position, lines) {
    let names = list.map(lines, fn(line) { line.name })
    let indent =
      lines
      |> list.map(fn(line) { line.indent })
      |> list.fold(0, int.max)
    Label(position: position, names: names, indent: indent)
  })
  |> map.values()
}

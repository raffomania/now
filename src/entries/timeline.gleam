import gleam/int
import gleam/result
import entries/db_entries
import birl/time
import gleam/list
import gleam/map
import gleam/option
import projects

const day_in_seconds = 86_400

pub type Line {
  Line(project: projects.Project, start: Int, end: Int, indent: Int)
}

pub type Timeline =
  map.Map(projects.Id, Line)

pub fn new() -> Timeline {
  map.new()
}

pub fn from_entries(entries: List(db_entries.EntryWithProject)) -> Timeline {
  entries
  |> to_lines
  |> map.values
  |> list.sort(fn(a, b) { int.compare(a.start, b.start) })
  |> list.fold(new(), add_line)
}

fn to_lines(entries: List(db_entries.EntryWithProject)) -> Timeline {
  use timeline, entry <- list.fold(entries, new())
  use maybe_line <- map.update(timeline, entry.entry.project_id)

  case maybe_line {
    option.Some(line) -> add_entry_to_line(line, entry.entry)
    option.None ->
      Line(
        project: entry.project,
        start: date_to_grid_position(entry.entry.datetime),
        end: date_to_grid_position(entry.entry.datetime),
        indent: 0,
      )
  }
}

fn add_line(timeline: Timeline, line: Line) -> Timeline {
  let overlapping_indents =
    map.values(timeline)
    |> list.filter(overlapping(_, line))
    |> list.filter(fn(other) { other.project.id != line.project.id })
    |> list.map(fn(line) { line.indent })

  let largest_overlapping_indent =
    overlapping_indents
    |> list.fold(0, int.max)

  let first_non_overlapping_indent =
    list.range(0, largest_overlapping_indent)
    |> list.find(fn(indent) { !list.contains(overlapping_indents, indent) })
    |> result.unwrap(largest_overlapping_indent + 1)

  map.insert(
    timeline,
    line.project.id,
    Line(..line, indent: first_non_overlapping_indent),
  )
}

pub fn overlapping(a: Line, b: Line) -> Bool {
  a.start <= b.end && a.end >= b.start
}

fn date_to_grid_position(date_time: time.DateTime) -> Int {
  let to_bucket = fn(date_time: time.DateTime) -> Int {
    let timestamp = time.to_unix(date_time)
    timestamp / day_in_seconds
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
    let names = list.map(lines, fn(line) { line.project.name })
    let indent =
      lines
      |> list.map(fn(line) { line.indent })
      |> list.fold(0, int.max)
    Label(position: position, names: names, indent: indent)
  })
  |> map.values()
}

import gleam/int
import gleam/set
import gleam/list
import gleam/map
import gleam/io
import gleam/option
import entries/debug

pub type Line {
  Line(name: String, start: Int, end: Int, indent: Int)
}

pub type Timeline =
  map.Map(String, Line)

pub fn new() -> Timeline {
  map.new()
}

pub fn add_entry(timeline: Timeline, new_entry: debug.Entry) -> Timeline {
  map.update(
    timeline,
    new_entry.name,
    fn(maybe_line) {
      let line = case maybe_line {
        option.Some(line) -> add_entry_to_line(line, new_entry)
        option.None ->
          Line(
            name: new_entry.name,
            start: new_entry.position,
            end: new_entry.position,
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

fn add_entry_to_line(line: Line, new_entry: debug.Entry) -> Line {
  let new_start = int.min(line.start, new_entry.position)
  let new_end = int.max(line.end, new_entry.position)
  Line(..line, start: new_start, end: new_end)
}

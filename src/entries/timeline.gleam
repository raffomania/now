import gleam/int
import non_empty_list
import gleam/result
import entries/db_entries
import birl/time
import gleam/list
import gleam/map
import projects

const day_in_seconds = 86_400

pub type LinePart {
  LinePart(start: Int, end: Int)
}

pub type Line {
  Line(
    project: projects.Project,
    parts: non_empty_list.NonEmptyList(LinePart),
    indent: Int,
  )
}

pub type Timeline =
  map.Map(projects.Id, Line)

pub fn new() -> Timeline {
  map.new()
}

pub fn from_entries(entries: List(db_entries.EntryWithProject)) -> Timeline {
  let entries_by_project =
    entries
    |> list.group(fn(e) { e.project })

  entries_by_project
  |> to_lines
  |> list.sort(fn(a, b) { int.compare(line_start(a), line_start(b)) })
  |> list.fold(new(), add_line)
}

fn to_lines(
  entries_by_project: map.Map(
    projects.Project,
    List(db_entries.EntryWithProject),
  ),
) -> List(Line) {
  use lines, project, entries <- map.fold(entries_by_project, [])

  case entries {
    [head, ..rest] -> {
      let ne_list =
        non_empty_list.new(head, rest)
        |> non_empty_list.map(fn(e) { e.entry })

      list.prepend(lines, entries_to_line(ne_list, project))
    }
    [] -> lines
  }
}

fn line_start(line: Line) -> Int {
  line.parts
  |> non_empty_list.map(fn(line) { line.start })
  |> non_empty_list.reduce(int.min)
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
  list.any(
    non_empty_list.to_list(a.parts),
    fn(part_a) {
      list.any(
        non_empty_list.to_list(b.parts),
        fn(part_b) { part_overlapping(part_a, part_b) },
      )
    },
  )
}

pub fn part_overlapping(a: LinePart, b: LinePart) -> Bool {
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

fn fold_non_empty_list(
  over list: non_empty_list.NonEmptyList(a),
  from initial: acc,
  with fun: fn(acc, a) -> acc,
) -> acc {
  let first_result = fun(initial, list.first)
  list.fold(list.rest, first_result, fun)
}

fn entries_to_line(
  entries: non_empty_list.NonEmptyList(db_entries.Entry),
  project: projects.Project,
) -> Line {
  let positions =
    entries
    |> non_empty_list.map(fn(e) { date_to_grid_position(e.datetime) })
    |> non_empty_list.sort(int.compare)

  let first_part = LinePart(start: positions.first, end: positions.first + 1)

  let merge_or_add_part = fn(
    parts: non_empty_list.NonEmptyList(LinePart),
    new_position,
  ) {
    // Since positions are sorted, new_position is
    // always >= the end of the previous part
    let can_merge_into_previous_part = new_position - parts.first.end <= 3

    case can_merge_into_previous_part {
      True ->
        // Extend previous part and replace it in list
        non_empty_list.NonEmptyList(
          first: extend_line_part(parts.first, new_position + 1),
          rest: parts.rest,
        )
      False ->
        // Create new part and prepend it to list
        non_empty_list.prepend(
          parts,
          LinePart(start: new_position, end: new_position + 1),
        )
    }
  }

  let parts =
    positions
    |> fold_non_empty_list(
      from: non_empty_list.single(first_part),
      with: merge_or_add_part,
    )

  Line(project: project, parts: parts, indent: 0)
}

fn extend_line_part(line: LinePart, entry_position: Int) -> LinePart {
  LinePart(
    start: int.min(line.start, entry_position),
    end: int.max(line.end, entry_position),
  )
}

pub type Label {
  Label(names: List(String), position: Int, indent: Int)
}

pub fn labels(timeline: Timeline) -> List(Label) {
  let exploded_lines =
    timeline
    |> map.values()
    |> list.flat_map(fn(line) {
      line.parts
      |> non_empty_list.map(fn(part) {
        Line(..line, parts: non_empty_list.single(part))
      })
      |> non_empty_list.to_list
    })

  exploded_lines
  |> list.group(fn(line) { line.parts.first.start })
  |> map.map_values(fn(position, parts) {
    let names = list.map(parts, fn(line) { line.project.name })
    let indent =
      parts
      |> list.map(fn(line) { line.indent })
      |> list.fold(0, int.max)
    Label(position: position, names: names, indent: indent)
  })
  |> map.values()
}

import entries/timeline
import projects
import entries/db_entries
import gleeunit/should
import gleam/option
import gleam/map
import birl/time
import birl/duration

pub fn lines_overlapping_test() {
  let line = fn(start: Int, end: Int) {
    timeline.LinePart(start: start, end: end)
  }

  timeline.part_overlapping(line(0, 1), line(2, 3))
  |> should.be_false()

  timeline.part_overlapping(line(2, 3), line(0, 1))
  |> should.be_false()

  timeline.part_overlapping(line(0, 1), line(1, 2))
  |> should.be_true()

  timeline.part_overlapping(line(0, 3), line(1, 2))
  |> should.be_true()

  timeline.part_overlapping(line(2, 3), line(1, 2))
  |> should.be_true()
}

fn gen_entry(offset offset: Int, project project_id: Int) {
  db_entries.EntryWithProject(
    entry: db_entries.Entry(
      id: 0,
      note: option.None,
      datetime: time.now()
      |> time.subtract(duration.days(offset)),
      project_id: project_id,
    ),
    project: projects.Project(id: project_id, name: ""),
  )
}

pub fn add_entry_indent_test() {
  let to_indents = fn(lines: timeline.Timeline) {
    lines
    |> map.map_values(fn(_, line: timeline.Line) { line.indent })
  }

  let timeline =
    timeline.from_entries([
      gen_entry(offset: 0, project: 0),
      gen_entry(offset: 1, project: 0),
    ])

  timeline
  |> to_indents()
  |> should.equal(map.from_list([#(0, 0)]))

  let timeline =
    timeline.from_entries([
      // The ordering is important here
      // to test for correct sorting in the timeline
      // logic
      gen_entry(offset: 1, project: 0),
      gen_entry(offset: 0, project: 1),
      gen_entry(offset: 2, project: 1),
    ])

  // check that the later project has the larger indent
  // to prevent lines overlapping with labels
  // of later lines
  timeline
  |> to_indents()
  |> should.equal(map.from_list([#(1, 0), #(0, 1)]))
}

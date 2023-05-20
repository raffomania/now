import entries/timeline
import gleeunit/should

pub fn lines_overlapping_test() {
  let line = fn(start: Int, end: Int) {
    timeline.Line(name: "", start: start, end: end, indent: 0)
  }

  timeline.overlapping(line(0, 1), line(2, 3))
  |> should.be_false()

  timeline.overlapping(line(2, 3), line(0, 1))
  |> should.be_false()

  timeline.overlapping(line(0, 1), line(1, 2))
  |> should.be_true()

  timeline.overlapping(line(0, 3), line(1, 2))
  |> should.be_true()

  timeline.overlapping(line(2, 3), line(1, 2))
  |> should.be_true()
}

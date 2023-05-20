import nakai/html as h
import nakai/html/attrs as a
import entries/timeline
import entries/debug
import gleam/list
import gleam/float
import gleam/io
import gleam/string
import gleam/pair
import gleam/int
import gleam/map

pub fn view(entries: List(debug.Entry)) -> h.Node(_) {
  let rendered_entries =
    entries
    |> list.fold(timeline.new(), timeline.add_entry)
    |> map.values()
    |> io.debug()
    |> list.map(entry)

  let styles =
    ["/static/preflight.css", "/static/main.css"]
    |> list.map(fn(file) { h.link([a.href(file), a.rel("stylesheet")]) })

  h.body(
    [],
    [
      h.Head(styles),
      h.main(
        [],
        [
          h.form(
            [a.action("/entries"), a.Attr("method", "POST")],
            [text_input("name", "Add Entry")],
          ),
          h.div([a.class("entries-container")], rendered_entries),
        ],
      ),
    ],
  )
}

fn text_input(name: String, label: String) {
  h.div(
    [],
    [
      h.label([a.for(name), a.Attr("hidden", "true")], [h.Text(label)]),
      h.input([a.type_("text"), a.name(name), a.id(name)]),
    ],
  )
}

fn style_from_map(styles: List(#(String, String))) -> String {
  styles
  |> list.map(fn(style) {
    string.concat([pair.first(style), ": ", pair.second(style), "; "])
  })
  |> string.concat
}

fn entry(entry: timeline.Line) -> h.Node(_) {
  let x_scale = 0.5
  let y_scale = 2.5
  let top = int.to_float(entry.start) *. y_scale
  let height = int.to_float(entry.end - entry.start) *. y_scale
  let left = int.to_float(entry.indent) *. x_scale
  let style =
    style_from_map([
      #("top", float.to_string(top) <> "rem"),
      #("height", float.to_string(height) <> "rem"),
      #("left", float.to_string(left) <> "rem"),
    ])
  h.div(
    [a.class("entry"), a.style(style)],
    [h.div([a.class("line")], []), h.p([], [h.Text(entry.name)])],
  )
}

import nakai/html as h
import nakai/html/attrs as a
import entries/timeline
import entries/db_entries
import gleam/list
import gleam/float
import gleam/string
import gleam/pair
import gleam/int
import gleam/map

const x_scale = 0.5

const y_scale = 2.5

pub fn view(entries: List(db_entries.EntryWithProject)) -> h.Node(_) {
  let timeline = timeline.from_entries(entries)
  let rendered_entries =
    timeline
    |> map.values()
    |> list.map(render_line)

  let rendered_labels =
    timeline.labels(timeline)
    |> list.map(render_label)

  let styles =
    ["/static/preflight.css", "/static/main.css"]
    |> list.map(fn(file) { h.link([a.href(file), a.rel("stylesheet")]) })

  h.Body(
    [],
    [
      h.Head([h.title("now"), ..styles]),
      h.main(
        [],
        [
          h.form(
            [a.action("/entries"), a.Attr("method", "POST")],
            [text_input("text", "Add Entry")],
          ),
          h.div(
            [a.class("entries-container")],
            list.append(rendered_entries, rendered_labels),
          ),
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

fn render_line(entry: timeline.Line) -> h.Node(_) {
  let top = int.to_float(entry.parts.first.start) *. y_scale
  let height =
    int.to_float(entry.parts.first.end - entry.parts.first.start) *. y_scale
  let left = int.to_float(entry.indent) *. x_scale
  let style =
    style_from_map([
      #("top", float.to_string(top) <> "rem"),
      #("height", float.to_string(height) <> "rem"),
      #("left", float.to_string(left) <> "rem"),
    ])

  h.div([a.class("line"), a.style(style)], [])
}

fn render_label(label: timeline.Label) -> h.Node(_) {
  let top = int.to_float(label.position) *. y_scale
  let left = int.to_float(label.indent) *. x_scale
  let style =
    style_from_map([
      #("top", float.to_string(top) <> "rem"),
      #("left", float.to_string(left) <> "rem"),
    ])

  let text = string.join(label.names, ", ")

  h.p([a.class("entry-label"), a.style(style)], [h.Text(text)])
}

fn style_from_map(styles: List(#(String, String))) -> String {
  styles
  |> list.map(fn(style) {
    string.concat([pair.first(style), ": ", pair.second(style), "; "])
  })
  |> string.concat
}

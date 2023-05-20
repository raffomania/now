import nakai/html as h
import nakai/html/attrs as a
import entries/db_entries
import gleam/list
import gleam/string
import gleam/pair
import gleam/int

type ViewEntry {
  SingleViewEntry(name: String, start: Int, end: Int, indent: Int)
}

fn entry_to_view_entry(entry: db_entries.Entry) -> ViewEntry {
  SingleViewEntry(name: entry.name, start: 0, end: 4, indent: 0)
}

pub fn view(entries: List(db_entries.Entry)) -> h.Node(_) {
  let rendered_entries =
    entries
    |> list.map(entry_to_view_entry)
    |> list.map(entry)
    |> list.map(fn(e) { h.li([], [e]) })
  let rendered_entry_list = h.ul([], rendered_entries)

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
          h.div([a.class("entries-container")], [rendered_entry_list]),
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

fn entry(entry: ViewEntry) -> h.Node(_) {
  let style =
    style_from_map([
      #("top", int.to_string(entry.start) <> "rem"),
      #("left", int.to_string(entry.indent) <> "rem"),
      #("height", int.to_string(entry.end - entry.start) <> "rem"),
    ])
  h.div(
    [a.class("entry"), a.style(style)],
    [h.div([a.class("line")], []), h.p([], [h.Text(entry.name)])],
  )
}

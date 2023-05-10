import nakai/html as h
import nakai/html/attrs as a
import database/entries
import gleam/list

pub fn view(entriess: List(entries.Entry)) -> h.Node(_) {
  let rendered_entries =
    entriess
    |> list.map(entry)
    |> list.map(fn(e) { h.li([], [e]) })
  let rendered_entry_list = h.ul([], rendered_entries)

  h.body(
    [],
    [
      h.h1_text([], "Bonjour"),
      h.form(
        [a.action("/entries"), a.Attr("method", "POST")],
        [text_input("name", "Add Entry")],
      ),
      rendered_entry_list,
    ],
  )
}

fn entry(entry: entries.Entry) -> h.Node(_) {
  h.Text(entry.name)
}

fn text_input(name: String, label: String) {
  h.div(
    [],
    [
      h.label([a.for(name)], [h.Text(label)]),
      h.input([a.type_("text"), a.name(name), a.id(name)]),
    ],
  )
}

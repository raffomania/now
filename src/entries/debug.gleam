pub type Entry {
  Entry(name: String, position: Int)
}

pub fn test_data_entries() -> List(Entry) {
  [
    Entry("now", 0),
    Entry("now", 2),
    Entry("now", 3),
    Entry("elokon", 0),
    Entry("space game", 2),
    Entry("space game", 3),
    Entry("space game", 5),
    Entry("knakk", 5),
    Entry("knakk", 10),
  ]
}

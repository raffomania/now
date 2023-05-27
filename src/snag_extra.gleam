import snag

pub fn try(
  result: Result(ok_a, Nil),
  issue: String,
  fun: fn(ok_a) -> snag.Result(ok_b),
) -> snag.Result(ok_b) {
  case result {
    Ok(val) -> fun(val)
    Error(_) -> snag.error(issue)
  }
}

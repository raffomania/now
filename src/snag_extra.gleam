import snag
import gleam/io
import gleam/result

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

pub fn print_if_error(body: fn() -> snag.Result(a)) -> snag.Result(a) {
  let result = body()
  result.map_error(
    result,
    fn(err) {
      io.println(snag.pretty_print(err))
      err
    },
  )
}

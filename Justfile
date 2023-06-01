watch:
    watchexec -r -c -w src gleam run

export:
    gleam clean
    gleam export erlang-shipment
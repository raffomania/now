watch:
    watchexec -r -c -w src gleam run

test:
    gleam test

seed:
    gleam run -m seed

export:
    gleam export erlang-shipment
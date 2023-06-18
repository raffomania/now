watch:
    watchexec -r -c -w src gleam run

test:
    gleam test

seed:
    gleam run -m seed

reset-db:
    rm now.sqlite

export:
    gleam export erlang-shipment
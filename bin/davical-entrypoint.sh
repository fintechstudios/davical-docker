#!/bin/bash
set -e

if [ "$RUN_MIGRATIONS_AT_STARTUP" = true ] && [ "$1" != "run-migrations" ]; then
  run-migrations
fi

exec "$@"

#!/bin/sh

for script in ./scripts/*; do
  if [ -f "$script" ]; then
  echo "Sourcing $script..."
  . $script;
  fi
done

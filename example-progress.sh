#!/bin/bash
echo foo

total=30
for i in {1..5}; do
  echo [$i/$total] miau
  sleep 0.1s
done

total=50
for i in {5..50}; do
  echo [$i/$total] miau
  if [ $i -eq 15 ]; then
    echo bar
    fi
  sleep 0.2s
done
echo foo bar

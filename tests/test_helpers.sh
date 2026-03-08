#!/usr/bin/env bash

assert_eq() {
  local expected="${1:-}"
  local actual="${2:-}"
  local message="${3:-assert_eq failed}"

  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $message"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    return 1
  fi
}

assert_contains() {
  local text="${1:-}"
  local pattern="${2:-}"
  local message="${3:-assert_contains failed}"

  if [[ "$text" != *"$pattern"* ]]; then
    echo "FAIL: $message"
    echo "  text:    $text"
    echo "  pattern: $pattern"
    return 1
  fi
}

run_and_capture() {
  local output_var="${1:?missing output var name}"
  local status_var="${2:?missing status var name}"
  shift 2

  local cmd_output cmd_status
  set +e
  cmd_output="$($@)"
  cmd_status=$?
  set -e

  printf -v "$output_var" '%s' "$cmd_output"
  printf -v "$status_var" '%s' "$cmd_status"
}

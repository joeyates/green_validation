#!/usr/bin/env elixir

Mix.install([{:green_validation, path: __DIR__ |> Path.join("..") |> Path.expand()}])

GreenValidation.CLI.HexpmPackages.main(System.argv())

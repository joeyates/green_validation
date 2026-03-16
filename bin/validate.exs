#!/usr/bin/env elixir

Mix.install([{:green_validation, path: __DIR__ |> Path.join("..") |> Path.expand()}])

Application.stop(:logger)
Application.put_env(:logger, :console, format: "$time $metadata[$level] $message\n")
{:ok, _} = Application.ensure_all_started(:logger)

GreenValidation.CLI.Validate.main(System.argv())

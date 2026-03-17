import Config

Application.stop(:logger)
Application.put_env(:logger, :console, format: "$time $metadata[$level] $message\n")
{:ok, _} = Application.ensure_all_started(:logger)

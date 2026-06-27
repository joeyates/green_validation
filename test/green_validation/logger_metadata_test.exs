defmodule GreenValidation.LoggerMetadataTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias GreenValidation.CLI.Validate

  require Logger

  test "the project name in the Logger metadata is printed in log messages" do
    log =
      capture_log(fn ->
        Logger.metadata(project: "phoenix")
        Logger.info("Compiling project")
      end)

    assert log =~ "project=phoenix"
  end

  describe "configure_logger/0" do
    test "applies the project metadata formatter to the running default handler" do
      Validate.configure_logger()

      {:ok, config} = :logger.get_handler_config(:default)
      {Logger.Formatter, formatter} = config[:formatter]

      assert :project in formatter.metadata
      refute match?(["\n" | _], formatter.template)
    end
  end
end


defmodule IE do
  @moduledoc false

  # Functions for iex session...
  #
  # Examples:
  #   require IE
  #   IE.use

  defmacro use do
    quote do
      alias NOAA.{Observations, Observations.CLI}
      :ok
    end
  end
end

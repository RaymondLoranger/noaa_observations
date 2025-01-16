defmodule NOAA.Observations.TopSup do
  use Application

  alias __MODULE__
  alias NOAA.Observations.TemplatesAgent

  @spec start(Application.start_type(), term) :: {:ok, pid}
  def start(_start_type, _start_args = :ok) do
    [
      # Child spec relying on `use Agent`...
      {TemplatesAgent, :ok}
    ]
    |> Supervisor.start_link(name: TopSup, strategy: :one_for_one)
  end
end

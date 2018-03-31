use Mix.Config

config :noaa_observations,
  book_ref:
    """
    Exercise in the book [Programming Elixir]
    (https://pragprog.com/book/elixir16/
    programming-elixir-1-6) by Dave Thomas.
    """
    |> String.replace("\n", "")

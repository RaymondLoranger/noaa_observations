# NOAA Observations

[![Build Status](https://travis-ci.org/RaymondLoranger/noaa_observations.svg?branch=master)](https://travis-ci.org/RaymondLoranger/noaa_observations)

Writes NOAA Observations to stdout in a table with borders and colors.

##### Exercise in the book [Programming Elixir](https://pragprog.com/book/elixir16/programming-elixir-1-6) by Dave Thomas.

## Using

To use `NOAA Observations`, first clone it from GitHub:

  - git clone https://github.com/RaymondLoranger/noaa_observations

Then run these commands to build the escript:

  - cd noaa_observations
  - mix deps.get
  - mix escript.build

Now you can run the application like so on Windows:

  - escript no --help
  - escript no ny 9 -blt dark

On macOS, you would run the application as follows:

  - ./no --help
  - ./no ny 9 --last --table-style=dark

## Examples
## ![pretty](images/pretty.png)
## ![pretty_alt](images/pretty_alt.png)
## ![pretty_mult](images/pretty_mult.png)
## ![dotted](images/dotted.png)
## ![dotted_alt](images/dotted_alt.png)
## ![dotted_mult](images/dotted_mult.png)

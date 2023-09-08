defmodule RinhaTest do
  use ExUnit.Case
  doctest Rinha

  # test "greets the world" do
  #   file = File.read!("#{__DIR__}/fib.json")
  #   assert Rinha.compile(file) == :world
  # end

  test "Fibonnaci" do
    file = File.read!("#{__DIR__}/fib.json")
    fib = Rinha.compile(file)
    program_code = """
    fib = fn n ->
      if n < 2 do
        n
      else
        fib(n - 1) + fib(n - 2)
      end
    end

    IO.puts(fib(10))
    """ |> String.trim()

    assert Macro.to_string(fib) == program_code

  end

  test "compile var" do
    input = %{
      "kind" => "Var",
      "text" => "n",
      "location" => %{
        "start" => 28,
        "end" => 29,
        "filename" => "files/fib.rinha"
      }
    }

    assert {:n, _, Rinha} = Rinha.do_compile(input)
  end

  test "compile int" do
    input = %{
      "kind" => "Int",
      "value" => 2,
      "location" => %{
        "start" => 32,
        "end" => 33,
        "filename" => "files/fib.rinha"
      }
    }

    assert 2 == Rinha.do_compile(input)
  end

  test "compile condition <" do
    input = %{
      "kind" => "Binary",
      "lhs" => %{
        "kind" => "Var",
        "text" => "n",
        "location" => %{
          "start" => 28,
          "end" => 29,
          "filename" => "files/fib.rinha"
        }
      },
      "op" => "Lt",
      "rhs" => %{
        "kind" => "Int",
        "value" => 2,
        "location" => %{
          "start" => 32,
          "end" => 33,
          "filename" => "files/fib.rinha"
        }
      },
      "location" => %{"start" => 28, "end" => 33, "filename" => "files/fib.rinha"}
    }

    assert {
             :<,
             [context: Rinha, imports: [{2, Kernel}]],
             [_, 2]
           } = Rinha.do_compile(input)
  end

  test "compile simple function" do
    input = %{
      "kind" => "Function",
      "value" => %{
        "kind" => "Int",
        "value" => 2,
        "location" => %{
          "start" => 79,
          "end" => 80,
          "filename" => "files/fib.rinha"
        }
      },
      "parameters" => [%{"text" => "a"}, %{"text" => "b"}],
      "location" => %{
        "start" => 32,
        "end" => 33,
        "filename" => "files/fib.rinha"
      }
    }

    function = Rinha.do_compile(input)
    assert Macro.to_string(function) == "fn a, b -> 2 end"
    assert {:fn, [], [{:->, [], [[{:a, [], Rinha}, {:b, [], Rinha}], 2]}]} == function
  end

  test "call variable" do
    input = %{
      "kind" => "Call",
      "callee" => %{
        "kind" => "Var",
        "text" => "fib",
        "location" => %{
          "start" => 71,
          "end" => 74,
          "filename" => "files/fib.rinha"
        }
      },
      "arguments" => [
        %{
          "kind" => "Binary",
          "lhs" => %{
            "kind" => "Var",
            "text" => "n",
            "location" => %{
              "start" => 75,
              "end" => 76,
              "filename" => "files/fib.rinha"
            }
          },
          "op" => "Sub",
          "rhs" => %{
            "kind" => "Int",
            "value" => 2,
            "location" => %{
              "start" => 79,
              "end" => 80,
              "filename" => "files/fib.rinha"
            }
          },
          "location" => %{
            "start" => 75,
            "end" => 80,
            "filename" => "files/fib.rinha"
          }
        }
      ],
      "location" => %{
        "start" => 71,
        "end" => 81,
        "filename" => "files/fib.rinha"
      }
    }

    assert {:fib, [],
            [{:-, [context: Rinha, imports: [{1, Kernel}, {2, Kernel}]], [{:n, [], Rinha}, 2]}]} ==
             Rinha.do_compile(input)
  end
end

defmodule Rinha do
  @spec compile(String.t()) :: nil
  def compile(file) do
    ast = Jason.decode!(file)
    do_compile(ast)
  end

  def do_compile(%{
        "location" => loc,
        "name" => file,
        "expression" => expression
      }) do
    do_compile(expression)
  end

  def do_compile(%{
        "kind" => "Let",
        "location" => loc,
        "name" => %{
          "text" => text
        },
        "value" => value,
        "next" => next
      }) do
    var = Macro.var(String.to_atom(text), __MODULE__)
    next = do_compile(next)

    quote do
      unquote(var) = unquote(do_compile(value))
      unquote(next)
    end
  end

  def do_compile(%{
    "kind" => "Print",
    "location" => loc,
    "value" => value,
  }) do
    quote do
      IO.puts(unquote(do_compile(value)))
    end
  end

  def do_compile(%{
        "kind" => "Call",
        "location" => loc,
        "callee" => %{
          "kind" => "Var",
          "text" => text,
          "location" => call_loc
        },
        "arguments" => arguments
      }) do
    arguments = Enum.map(arguments, fn x -> do_compile(x) end)

    quote do
      unquote(String.to_atom(text))(unquote_splicing(arguments))
    end
  end

  def do_compile(%{
        "kind" => "Function",
        "location" => loc,
        "value" => value,
        "parameters" => parameters
      }) do
    parameters =
      Enum.map(parameters, fn %{"text" => text} ->
        Macro.var(String.to_atom(text), __MODULE__)
      end)

    quote do
      fn unquote_splicing(parameters) -> unquote(do_compile(value)) end
    end
  end

  def do_compile(%{
        "kind" => "If",
        "location" => loc,
        "condition" => condition,
        "then" => then,
        "otherwise" => otherwise
      }) do
    quote do
      if unquote(do_compile(condition)) do
        unquote(do_compile(then))
      else
        unquote(do_compile(otherwise))
      end
    end
  end

  def do_compile(%{
        "kind" => "Binary",
        "op" => "Add",
        "location" => loc,
        "lhs" => lhs,
        "rhs" => rhs
      }) do
    quote do
      unquote(do_compile(lhs)) + unquote(do_compile(rhs))
    end
  end

  def do_compile(%{
        "kind" => "Binary",
        "op" => "Sub",
        "location" => loc,
        "lhs" => lhs,
        "rhs" => rhs
      }) do
    quote do
      unquote(do_compile(lhs)) - unquote(do_compile(rhs))
    end
  end

  def do_compile(%{
        "kind" => "Binary",
        "op" => "Lt",
        "location" => loc,
        "lhs" => lhs,
        "rhs" => rhs
      }) do
    quote do
      unquote(do_compile(lhs)) < unquote(do_compile(rhs))
    end
  end

  def do_compile(%{
        "kind" => "Var",
        "location" => loc,
        "text" => text
      }) do
    Macro.var(String.to_atom(text), __MODULE__)
  end

  def do_compile(%{
        "kind" => "Int",
        "location" => loc,
        "value" => value
      }) do
    value
  end

end

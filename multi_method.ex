# One approach
defmodule Shape do
  defstruct []
end

defmodule Square do
  defstruct [:side]
end

defprotocol Is do
  def a?(thing, other_thing)
end

defimpl Is, for: Shape do
  def a?(%Shape{}, %Square{}), do: true
  def a?(_, _), do: false
end

Is.a?(%Shape{}, %Square{})
# ========================================================== #
# Another approach; duck typing

defprotocol Shape do
  def area(shape)
  def perimeter(shape)
end

defmodule Square do
  defstruct [:side]

  defimpl Shape do
    def area(_) do
      10
    end

    def perimeter(_) do
      20
    end
  end
end

defmodule Is do
  def a?(protocol, data_type) do
    if protocol == data_type do
      true
    else
      not is_nil(protocol.impl_for(data_type))
    end
  end
end

# This is good if we know all relations are defined in terms
# of implementing an interface. Although strictly this should
# always be true, it may become cumbersome very quickly as
# we would have to define an interface and implement it in
# order to be able to say one thing is another thing.
# Also not much in the way of error checking here, could
# produce v weird errors if shit goes wrong.
Is.a?(Shape, %Square{})
# but this should still work
# pattern matching, but if that fails, the
# is_a? relation
Is.a?(1, 1)
Is.a?(Integer, 1)

# Now we have an is_a relation for any arb type of thing.
# Now we need to implement dispatching based on that.

defmodule Multi do
  defmacro define(name, function) do
    quote do
      defprotocol unquote(name) do
        defstruct fun: unquote(function)
        def run(a, b)
      end
    end
  end

  defmacro create_functions(pattern, function) do
    quote do
      def thing(unquote(pattern)), do: unquote(function).()
    end
  end

  def method(multi, pattern, fun) do
    result = struct!(multi).fun.()
    # We need to add a catch all case to the pattern match
    # that calls the fun if the result Is.a? pattern
    result == pattern
    Is.a?(result, pattern)
    fun.(result)

    # create the functions put the pattern in it make a fallthrogh
  end
end

lion = %{species: :lion}
bunny = %{species: :bunny}

Multi.define(Encounter, fn animal, other_animal ->
  {animal.species, other_animal.species}
end)

# This is just pattern matching, the secret sauce is in dispatch
Multi.method(Encounter, {:bunny, :lion}, fn {:bunny, :lion} -> :run_away end)
Multi.method(Encounter, {:lion, :bunny}, fn {:lion, :bunny} -> :eat_bunny end)
Multi.method(Encounter, pattern, fun_to_run_in_case_of_match)

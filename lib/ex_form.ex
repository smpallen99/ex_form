defmodule ExForm do
  require Logger
  use Xain
  @moduledoc """
  Prototype for a helpers to generate html forms. Usable with Phoenix.
  """

  @doc """
  Generates a html form. 

  ## Syntax:
      1. pass model name atom and use input_field

      form_for :my_model, [url: "/"], fn(f) -> 
        f
        |> input_field(:name, my_model.name)
        |> submit("save")
      end

      2. pass model struct and use input

      form_for my_model, [url: "/"], fn(f) ->
        f
        |> input(:name)
        |> submit("save")
      end
  """
  def form_for(name_or_mode, opts \\ [], fun \\ nil)
  def form_for(%{__struct__: model_name} = model, opts, fun) do
    _form_for(model, underscore(model_name), opts, fun)
  end
  def form_for(model_name, opts, fun) do
    _form_for(nil, model_name, opts, fun)
  end
  defp _form_for(model, model_name, opts, fun) do
    method = Keyword.get(opts, :method, "post")
    url = Keyword.get(opts, :url, "/")
    charset = Keyword.get(opts, :charset, "UTF-8")
    csrf = Keyword.get(opts, :csrf, nil)
    class = case Keyword.get(opts, :class, nil) do
      nil -> ""
      other -> ".#{other}"
    end
    {put_method, method} = if method == :put, do: {true, :post}, else: {false, method}

    form_data = %{model: model, model_name: model_name, data: [], type: :form} 
    case fun do
      nil -> form_data
      other -> 
        # markup do
          form("#new_#{model_name}#{class}", method: method, 
                "accept-charset": charset, action: url) do
            get_put_input(put_method)
            get_csrf_input(csrf)

            other.(form_data)
          end
        # end
        #|> Phoenix.HTML.safe
    end
  end

  def get_csrf_input(nil), do: nil
  def get_csrf_input(csrf) do
    input type: :hidden, name: "_csrf_token", value: csrf
  end

  def get_put_input(true) do
    input(name: "_method", value: "put", type: "hidden")
  end
  def get_put_input(_), do: nil


  @doc """
  Generate an input field

  Generates an input field for the provided form data that includes a the given 
  model data.

  ## Syntax 

      input(form_data, :name, class: "one two", style: "some style")

  """
  def input_field(form_data, name, type \\ :text, value \\ "", opts \\ [])
  def input_field(%{model: model, data: data} = form_data, name, type, _, opts) when model != nil do
    _input_field(form_data, name, type, Map.get(model, name, nil), opts)
  end
  def input_field(%{} = form_data, name, type, value, opts) do
    _input_field(form_data, name, type, value, opts)
  end

  defp _input_field(%{data: data, model_name: model_name} = form_data, name, type, value, _opts) do
    input("##{model_name}_#{name}", type: type, name: "#{model_name}[#{name}]", value: value) 
    form_data
  end

  @doc """
  Generate a hidden field for form_data that does not include a model

  ## Syntax

      hidden_field(form_data, :group_id, my_model.group_id)
  """
  def hidden_field(form_data, name, value \\ nil, opts \\ []), do: input_field(form_data, name, "hidden", value, opts)

  @doc """
  Generate a submit button
  """
  def submit_field(%{data: data} = form_data, value \\ "submit", _opts \\ []) do 
    input type: :submit, name: :commit, value: value
    form_data
  end

  @doc """
  Generate a field set
  """
  def inputs(form_data, name \\ "", opts \\ [], fun) do
    fieldset do
      if name != "" do
        legend do
          span(name) 
        end
      end
      fun.()
    end
    form_data
  end 

  @doc """
  Generate the underscored model name, given the model Atom

  ## Syntax

    iex> underscore(MyProject.MyModel)
    :my_model
  """
  def underscore(module) do
    module
    |> Atom.to_string
    |> String.split(".")
    |> List.last
    |> Mix.Utils.underscore
  end

end

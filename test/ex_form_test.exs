defmodule ExFormTest do
  require Logger
  use Pavlov.Case
  import Pavlov.Syntax.Expect  
  use Xain

  defmodule SampleStruct do
    defstruct name: "", id: 1, private: ""
  end

  def to_eq_s(left, right) do
    expect Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, left, "") |> 
      to_eq Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, right, "") 
  end

  def to_include_list(left, right) do
    for item <- right do
      expect left |> to_include item
    end
  end

  it "underscores the module" do

    expect ExForm.underscore(%SampleStruct{}.__struct__) |> to_eq "sample_struct"
  end  

  it "handles hidden_field" do
    sample = %SampleStruct{name: "sample", private: "secret"}

    result = ExForm.form_for(:sample_struct, [url: "/"], fn(f) -> 
      f |> ExForm.hidden_field(:private, sample.private)
    end)
   
    expect result |> to_include_list ["id=\"new_sample_struct\"", "method=\"post\"", "action=\"/\"",
                                      "type=\"hidden\"", "id=\"sample_struct_private\"", 
                                      "name=\"sample_struct[private]\"", "value=\"secret\""]
  end

  it "handles hidden_field with model" do
    sample = %SampleStruct{name: "sample", private: "secret"}

    result = ExForm.form_for(sample, [url: "/"], fn(f) -> 
      f |> ExForm.hidden_field(:private)
    end)

    expect result |> to_include_list ["<input ", "type=\"hidden\"", "id=\"sample_struct_private\"", 
                          "name=\"sample_struct[private]\"", "value=\"secret\""] 

  end

  it "handles input and submit buttons" do
    sample = %SampleStruct{name: "sample", private: "secret"}

    result = ExForm.form_for(sample, [url: "/"], fn(f) -> 
      ExForm.input_field(f, :name)
      ExForm.submit_field f
    end)

    expect result 
      |> to_include_list ["<input ", "type=\"text\"", "id=\"sample_struct_name\"", 
                          "name=\"sample_struct[name]\"", "value=\"sample\"",
                          "<input ", "type=\"submit\"", "name=\"commit\"", "value=\"submit\""]

  end

  it "handles inputs" do
    sample = %SampleStruct{name: "sample", private: "secret"}

    result = ExForm.form_for(sample, [url: "/"], fn(f) -> 
      ExForm.inputs(f, "Section 1", fn -> 
        ExForm.input_field(f, :name)
      end)
      ExForm.inputs(f, fn -> 
        f |> ExForm.submit_field
      end)
    end)
    expect result 
      |> to_include_list ["<fieldset", 
                          "<legend>", "<span>Section 1</span>", 
                          "<input ", "type=\"submit\""]

  end

end

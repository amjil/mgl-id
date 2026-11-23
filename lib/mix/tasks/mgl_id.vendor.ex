defmodule Mix.Tasks.MglId.Vendor do
  @moduledoc """
  Copies sibling front-end packages into `assets/vendor`.

  Packages:

    * `mgl-common-ui` — JS/CSS from `mgl-common-ui.js`

  Source resolution (first match):

    1. env var `MGL_COMMON_UI_PATH`
    2. `:mgl_id` application config `:mgl_common_ui_path`
    3. sibling checkout at `../../js/mgl-common-ui.js` relative to this app

  If a source is missing, the existing vendor copy is kept so CI/deploy
  does not depend on sibling checkouts.
  """
  use Mix.Task

  @shortdoc "Vendor sibling JS packages into assets/vendor"

  @packages ~w(mgl-common-ui)

  @impl Mix.Task
  def run(args) do
    selected =
      case args do
        [] -> @packages
        names -> Enum.map(names, &normalize_name/1)
      end

    Enum.each(selected, &vendor_package!/1)
  end

  defp normalize_name(name) when name in @packages, do: name

  defp normalize_name(name) do
    Mix.raise(
      "Unknown vendor package #{inspect(name)}. Expected one of: #{Enum.join(@packages, ", ")}"
    )
  end

  defp vendor_package!("mgl-common-ui") do
    dest = Path.expand("assets/vendor/mgl-common-ui")
    src = resolve_source(:mgl_common_ui_path, "MGL_COMMON_UI_PATH", "mgl-common-ui.js")

    with_source(src, dest, "mgl-common-ui", fn root ->
      File.mkdir_p!(dest)
      copy_tree!(Path.join(root, "src"), dest)
      File.cp!(Path.join(root, "styles/mgl-common-ui.css"), Path.join(dest, "mgl-common-ui.css"))
      Mix.shell().info("Vendored mgl-common-ui from #{root}")
    end)
  end

  defp with_source(src, dest, label, fun) do
    cond do
      is_binary(src) and File.dir?(src) ->
        fun.(src)

      exists?(dest) ->
        Mix.shell().info("Keeping #{dest} (#{label} source not found)")

      true ->
        Mix.raise("""
        #{label} not found. Set MGL_COMMON_UI_PATH or clone it next to this app
        (expected under projects/js/mgl-common-ui.js).
        """)
    end
  end

  defp resolve_source(config_key, env_key, sibling_name) do
    System.get_env(env_key) ||
      Application.get_env(:mgl_id, config_key) ||
      Path.expand("../../js/#{sibling_name}", Path.dirname(Mix.Project.project_file()))
  end

  defp exists?(path) do
    File.dir?(path) or File.regular?(path)
  end

  defp copy_tree!(from, to) do
    Path.wildcard(Path.join(from, "**/*"))
    |> Enum.filter(&File.regular?/1)
    |> Enum.each(fn file ->
      rel = Path.relative_to(file, from)
      target = Path.join(to, rel)
      File.mkdir_p!(Path.dirname(target))
      File.cp!(file, target)
    end)
  end
end

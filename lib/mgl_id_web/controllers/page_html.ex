defmodule MglIdWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use MglIdWeb, :html

  import MglIdWeb.MnComponents

  embed_templates "page_html/*"
end

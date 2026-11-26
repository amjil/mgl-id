defmodule MglIdWeb.ErrorHTMLTest do
  use MglIdWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    html = render_to_string(MglIdWeb.ErrorHTML, "404", "html", [])
    assert html =~ "lang=\"mn-Mong\""
    assert html =~ "404"
    assert html =~ "ᠬᠠᠭᠤᠳᠠᠰᠤ ᠣᠯᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ"
  end

  test "renders 500.html" do
    html = render_to_string(MglIdWeb.ErrorHTML, "500", "html", [])
    assert html =~ "lang=\"mn-Mong\""
    assert html =~ "500"
    assert html =~ "ᠰᠧᠷᠸᠧᠷ ᠦᠨ ᠠᠯᠳᠠᠭ᠎ᠠ"
  end
end

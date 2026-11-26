defmodule MglIdWeb.ErrorHTML do
  @moduledoc """
  Traditional Mongolian vertical-lr HTML error pages.
  Renders a full standalone HTML document because `render_errors` uses `layout: false`.
  """
  use MglIdWeb, :html

  import MglIdWeb.MnComponents

  def render("404.html", assigns) do
    assigns
    |> Map.merge(%{
      status_code: "404",
      heading: "ᠬᠤᠤᠳᠠᠰᠤ ᠣᠯᠳᠠᠭᠰᠠᠨ ᠦᠭᠡᠢ",
      description: "ᠲᠠᠨ᠎ᠤ ᠬᠠᠢᠵᠤ ᠪᠤᠢ ᠬᠤᠤᠳᠠᠰᠤ ᠪᠠᠢᠬᠤ ᠦᠭᠡᠢ ᠪᠤᠶᠤ ᠰᠢᠯᠵᠢᠭᠦᠯᠦᠭᠳᠡᠭᠰᠡᠨ ᠪᠠᠢᠨ᠎ᠠ᠃",
      latin_description?: false
    })
    |> error_page()
  end

  def render("403.html", assigns) do
    assigns
    |> Map.merge(%{
      status_code: "403",
      heading: "ᠡᠷᠬᠡ ᠬᠦᠷᠦᠯᠴᠡᠬᠦ ᠦᠭᠡᠢ",
      description: "ᠲᠠ ᠡᠨᠡ ᠬᠤᠤᠳᠠᠰᠤ ᠳᠤ ᠨᠡᠪᠲᠡᠷᠡᠬᠦ ᠡᠷᠬᠡ ᠦᠭᠡᠢ ᠪᠠᠢᠨ᠎ᠠ᠃",
      latin_description?: false
    })
    |> error_page()
  end

  def render("500.html", assigns) do
    assigns
    |> Map.merge(%{
      status_code: "500",
      heading: "ᠰᠧᠷᠸᠧᠷ ᠦᠨ ᠠᠯᠳᠠᠭ᠎ᠠ",
      description: "ᠰᠢᠰᠲ᠋ᠧᠮ ᠳᠦ ᠲᠦᠷ ᠵᠤᠭᠤᠷ ᠤᠨ ᠠᠯᠳᠠᠭ᠎ᠠ ᠭᠠᠷᠪᠠ᠃ ᠲᠦᠷ ᠬᠦᠯᠢᠶᠡᠭᠡᠳ ᠳᠠᠬᠢᠨ ᠣᠷᠣᠯᠳᠤᠭᠠᠷᠠᠢ᠃",
      latin_description?: false
    })
    |> error_page()
  end

  def render(template, assigns) do
    status_code = String.replace_suffix(template, ".html", "")
    fallback_message = Phoenix.Controller.status_message_from_template(template)

    assigns
    |> Map.merge(%{
      status_code: status_code,
      heading: "ᠠᠯᠳᠠᠭ᠎ᠠ ᠭᠠᠷᠪᠠ",
      description: fallback_message,
      latin_description?: true
    })
    |> error_page()
  end

  defp error_page(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="mn-Mong" dir="ltr">
      <head>
        <meta charset="utf-8" />
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1, viewport-fit=cover"
        />
        <title>{@status_code} · Mgl ID</title>
        <link
          rel="preload"
          href={~p"/fonts/OyunQaganTig.ttf"}
          as="font"
          type="font/ttf"
          crossorigin
        />
        <link rel="stylesheet" href={~p"/assets/css/app.css"} />
      </head>
      <body>
        <.mn_shell title="Mgl ID">
          <article class="mn-doc">
            <.mn_page_head kicker={@status_code} title={@heading}>
              <p class={["mn-lead", if(@latin_description?, do: "mn-sideways", else: "mn-text")]}>
                {@description}
              </p>
            </.mn_page_head>
            <%!-- Use mn-actions so vertical buttons flow left -> right --%>
            <div class="mn-actions">
              <a href={~p"/"} class="mn-text btn btn-primary">ᠨᠢᠭᠤᠷ ᠬᠠᠭᠤᠳᠠᠰᠤ ᠲᠦ ᠪᠤᠴᠠᠬᠤ</a>
              <a href={~p"/login"} class="mn-text btn btn-ghost">ᠨᠡᠪᠲᠡᠷᠡᠬᠦ</a>
            </div>
          </article>
        </.mn_shell>
      </body>
    </html>
    """
  end
end

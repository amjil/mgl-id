defmodule MglIdWeb.Plugs.SecurityHeaders do
  @moduledoc """
  Hardened browser security headers for production traffic.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_resp_header(
      "permissions-policy",
      "camera=(), microphone=(), geolocation=(), payment=()"
    )
    |> put_resp_header("cross-origin-opener-policy", "same-origin")
    |> maybe_csp()
  end

  defp maybe_csp(conn) do
    # LiveView needs 'unsafe-inline'/'unsafe-eval' for phoenix.js in V1; tighten later with nonces.
    csp =
      [
        "default-src 'self'",
        "img-src 'self' data: https:",
        "font-src 'self' data:",
        "style-src 'self' 'unsafe-inline'",
        "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
        "connect-src 'self' wss: https:",
        "frame-ancestors 'none'",
        "base-uri 'self'",
        "form-action 'self'"
      ]
      |> Enum.join("; ")

    put_resp_header(conn, "content-security-policy", csp)
  end
end

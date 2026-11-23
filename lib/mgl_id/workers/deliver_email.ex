defmodule MglId.Workers.DeliverEmail do
  use Oban.Worker, queue: :mailers, max_attempts: 5

  alias MglId.Mailer

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(args["to"])
      |> Swoosh.Email.from({"Mgl ID", "noreply@id.amjil.net"})
      |> Swoosh.Email.subject(args["subject"])
      |> Swoosh.Email.text_body(args["text_body"])

    case Mailer.deliver(email) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end

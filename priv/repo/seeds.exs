# Seed a local admin for development.
# Password: change-me-now-12 (change immediately in shared environments)

alias MglId.{Accounts, Credentials, Repo}
alias MglId.Accounts.User

unless Repo.get_by(User, username_normalized: "idadmin") do
  {:ok, user} =
    Accounts.create_user(%{
      username: "idadmin",
      username_normalized: "idadmin",
      display_name: "ID Admin",
      status: "active",
      trust_level: "trusted",
      review_status: "approved",
      registration_source: "seed",
      is_admin: true
    })

  {:ok, _} = Credentials.create_password(user.id, "change-me-now-12")
  IO.puts("Seeded admin user: idadmin / change-me-now-12")
end

client = MglId.Clients.seed_dev_client!()
IO.puts("OAuth client id=#{client.id} secret=#{client.secret}")

for product <- MglId.Clients.seed_product_clients!() do
  IO.puts("Product OAuth client name=#{product.name} id=#{product.id} secret=#{product.secret}")
end

_ = MglId.Policies.ensure_default_roles!()
IO.puts("Ensured default admin RBAC role")

defmodule Strates.Factory do
  @moduledoc """
  Factory for creating entities via the `Strates` context.
  """
  use ExMachina.Ecto, repo: Strates.Repo

  alias Strates.Accounts.User

  def user_factory(attrs) do
    password = Map.get(attrs, :password, Faker.UUID.v4())
    attrs = Map.delete(attrs, :password)

    %User{
      email: Faker.Internet.email(),
      hashed_password: Bcrypt.hash_pwd_salt(password)
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end

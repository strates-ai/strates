defmodule Strates.Accounts.Register do
  @moduledoc """
  User registration.
  """
  alias Strates.Repo
  alias Strates.Accounts.User

  @doc """
  Registers a user.
  """
  @spec register_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  @spec change(User.t(), map()) :: Ecto.Changeset.t()
  def change(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end
end

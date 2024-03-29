defmodule Strates.Accounts.Session do
  @moduledoc """
  Session management.
  """
  alias Strates.Repo
  alias Strates.Accounts.{User, UserToken}

  @doc """
  Generates a session token.
  """
  @spec generate_token(User.t()) :: String.t()
  def generate_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  @spec get_user_by_token(String.t()) :: User.t() | nil
  def get_user_by_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_token(String.t()) :: :ok
  def delete_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end
end

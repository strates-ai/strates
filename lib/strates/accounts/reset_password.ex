defmodule Strates.Accounts.ResetPassword do
  @moduledoc """
  Resetting a password.
  """
  alias Strates.Repo
  alias Strates.Accounts.{User, UserToken, UserNotifier}

  @doc """
  Delivers the reset password email to the given user.
  """
  @spec deliver_instructions(User.t(), (String.t() -> String.t())) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def deliver_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_password_reset_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.
  """
  @spec get_user_by_token(String.t()) :: User.t() | nil
  def get_user_by_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.
  """
  @spec reset_password(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def reset_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end

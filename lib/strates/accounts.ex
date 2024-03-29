defmodule Strates.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Strates.Repo

  alias Strates.Accounts.User
  alias Strates.Accounts

  ## Database getters

  @doc """
  Gets a user by email.
  """
  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.
  """
  @spec get_user_by_email_and_password(String.t(), String.t()) :: User.t() | nil
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.
  """
  @spec get_user!(integer()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.
  """
  @spec register_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(attrs),
    do: Accounts.Register.register_user(attrs)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  @spec change_registration(User.t(), map()) :: Ecto.Changeset.t()
  def change_registration(%User{} = user, attrs \\ %{}),
    do: Accounts.Register.change(user, attrs)

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.
  """
  @spec change_email(User.t(), map()) :: Ecto.Changeset.t()
  def change_email(user, attrs \\ %{}),
    do: Accounts.Settings.change_email(user, attrs)

  @doc """
  Emulates that the email will change without actually changing
  it in the database.
  """
  @spec apply_email(User.t(), String.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def apply_email(user, password, attrs),
    do: Accounts.Settings.apply_email(user, password, attrs)

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  @spec update_email(User.t(), String.t()) :: :ok | :error
  def update_email(user, token),
    do: Accounts.Settings.update_email(user, token)

  @doc """
  Delivers the update email instructions to the given user.
  """
  @spec deliver_update_email_instructions(User.t(), String.t(), (String.t() -> String.t())) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1),
      do:
        Accounts.Settings.deliver_update_email_instructions(
          user,
          current_email,
          update_email_url_fun
        )

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.
  """
  @spec change_password(User.t(), map()) :: Ecto.Changeset.t()
  def change_password(user, attrs \\ %{}),
    do: Accounts.Settings.change_password(user, attrs)

  @doc """
  Updates the user password.
  """
  @spec update_password(User.t(), String.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_password(user, password, attrs),
    do: Accounts.Settings.update_password(user, password, attrs)

  ## Session

  @doc """
  Generates a session token.
  """
  @spec generate_session_token(User.t()) :: String.t()
  def generate_session_token(user),
    do: Accounts.Session.generate_token(user)

  @doc """
  Gets the user with the given signed token.
  """
  @spec get_user_by_session_token(String.t()) :: User.t() | nil
  def get_user_by_session_token(token),
    do: Accounts.Session.get_user_by_token(token)

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_session_token(String.t()) :: :ok
  def delete_session_token(token),
    do: Accounts.Session.delete_token(token)

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.
  """
  @spec deliver_confirmation_instructions(User.t(), (String.t() -> String.t())) ::
          :ok | {:error, :already_confirmed}
  def deliver_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1),
      do: Accounts.Confirm.deliver_instructions(user, confirmation_url_fun)

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  @spec confirm_user(String.t()) :: {:ok, User.t()} | :error
  def confirm_user(token), do: Accounts.Confirm.confirm_user(token)

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.
  """
  @spec deliver_password_reset_instructions(User.t(), (String.t() -> String.t())) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def deliver_password_reset_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1),
      do: Accounts.ResetPassword.deliver_instructions(user, reset_password_url_fun)

  @doc """
  Gets the user by reset password token.
  """
  @spec get_user_by_password_reset_token(String.t()) :: User.t() | nil
  def get_user_by_password_reset_token(token),
    do: Accounts.ResetPassword.get_user_by_token(token)

  @doc """
  Resets the user password.
  """
  @spec reset_password(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def reset_password(user, attrs),
    do: Accounts.ResetPassword.reset_password(user, attrs)
end

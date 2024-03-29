defmodule Strates.Accounts.ResetPasswordTest do
  @moduledoc """
  Tests for resetting passwords.
  """
  use Strates.DataCase

  import Strates.AccountsFixtures

  alias Strates.Repo
  alias Strates.Accounts
  alias Strates.Accounts.ResetPassword
  alias Strates.Accounts.{User, UserToken}
  alias Strates.Factory

  describe "deliver_instructions/2" do
    setup do
      %{user: Factory.insert(:user)}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          ResetPassword.deliver_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_token/1" do
    setup do
      user = Factory.insert(:user)

      token =
        extract_user_token(fn url ->
          ResetPassword.deliver_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = ResetPassword.get_user_by_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute ResetPassword.get_user_by_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute ResetPassword.get_user_by_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_password/2" do
    setup do
      %{user: Factory.insert(:user)}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        ResetPassword.reset_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = ResetPassword.reset_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = ResetPassword.reset_password(user, %{password: "new valid password"})
      assert is_nil(updated_user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_session_token(user)
      {:ok, _} = ResetPassword.reset_password(user, %{password: "new valid password"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end
end

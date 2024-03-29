defmodule Strates.Accounts.SessionTest do
  @moduledoc """
  Tests for user sessions.
  """
  use Strates.DataCase

  alias Strates.Accounts.UserToken
  alias Strates.Accounts.Session
  alias Strates.Factory

  describe "generate_token/1" do
    setup do
      %{user: Factory.insert(:user)}
    end

    test "generates a token", %{user: user} do
      token = Session.generate_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: Factory.insert(:user).id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_token/1" do
    setup do
      user = Factory.insert(:user)
      token = Session.generate_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Session.get_user_by_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Session.get_user_by_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Session.get_user_by_token(token)
    end
  end

  describe "delete_token/1" do
    test "deletes the token" do
      user = Factory.insert(:user)
      token = Session.generate_token(user)
      assert Session.delete_token(token) == :ok
      refute Session.get_user_by_token(token)
    end
  end
end

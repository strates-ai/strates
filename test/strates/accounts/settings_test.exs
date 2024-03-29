defmodule Strates.Accounts.SettingsTest do
  @moduledoc """
  Tests for user settings.
  """
  use Strates.DataCase

  import Strates.AccountsFixtures

  alias Strates.Accounts
  alias Strates.Accounts.{User, UserToken, Settings}
  alias Strates.Factory

  @valid_password Faker.UUID.v4()

  describe "change_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Settings.change_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_email/3" do
    setup do
      password = Faker.UUID.v4()
      %{user: Factory.insert(:user, password: password), password: password}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Settings.apply_email(user, @valid_password, %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Settings.apply_email(user, @valid_password, %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Settings.apply_email(user, @valid_password, %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user, password: password} do
      %{email: email} = Factory.insert(:user)

      {:error, changeset} = Settings.apply_email(user, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Settings.apply_email(user, "invalid", %{email: Faker.Internet.email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user, password: password} do
      email = Faker.Internet.email()
      {:ok, user} = Settings.apply_email(user, password, %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{user: Factory.insert(:user)}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Settings.deliver_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_email/2" do
    setup do
      user = Factory.insert(:user)
      email = Faker.Internet.email()

      token =
        extract_user_token(fn url ->
          Settings.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Settings.update_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Settings.update_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Settings.update_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Settings.update_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Settings.change_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Settings.change_password(%User{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_password/3" do
    setup do
      password = Faker.UUID.v4()
      %{user: Factory.insert(:user, password: password), password: password}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Settings.update_password(user, @valid_password, %{
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

      {:error, changeset} =
        Settings.update_password(user, @valid_password, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Settings.update_password(user, "invalid", %{password: @valid_password})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user, password: password} do
      IO.inspect(user.password, label: "pass")

      {:ok, user} =
        Settings.update_password(user, password, %{
          password: "new valid password"
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user, password: password} do
      _ = Accounts.generate_session_token(user)

      {:ok, _} =
        Settings.update_password(user, password, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end
end

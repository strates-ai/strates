defmodule Strates.Accounts.RegisterTest do
  @moduledoc """
  Tests for user registration.
  """
  use Strates.DataCase

  alias Strates.Accounts.Register
  alias Strates.Accounts.User
  alias Strates.Factory

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Register.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Register.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Register.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = Factory.insert(:user)
      {:error, changeset} = Register.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Register.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = Faker.Internet.email()
      password = Faker.UUID.v4()
      {:ok, user} = Register.register_user(%{email: email, password: password})
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Register.change(%User{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = Faker.Internet.email()
      password = Faker.UUID.v4()

      changeset =
        Register.change(%User{}, %{email: email, password: password})

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end
end

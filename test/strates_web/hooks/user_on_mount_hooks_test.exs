defmodule StratesWeb.UserOnMountHooksTest do
  use StratesWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Strates.Accounts
  alias StratesWeb.UserOnMountHooks
  alias Strates.Factory

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, StratesWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: Factory.insert(:user), conn: conn}
  end

  describe "on_mount :maybe_assign_user" do
    test "assigns current_user based on a valid user_token", %{conn: conn, user: user} do
      user_token = Accounts.generate_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      {:cont, updated_socket} =
        UserOnMountHooks.on_mount(:maybe_assign_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user.id == user.id
    end

    test "assigns nil to current_user assign if there isn't a valid user_token", %{conn: conn} do
      user_token = "invalid_token"
      session = conn |> put_session(:user_token, user_token) |> get_session()

      {:cont, updated_socket} =
        UserOnMountHooks.on_mount(:maybe_assign_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user == nil
    end

    test "assigns nil to current_user assign if there isn't a user_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        UserOnMountHooks.on_mount(:maybe_assign_user, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_user based on a valid user_token", %{conn: conn, user: user} do
      user_token = Accounts.generate_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      {:cont, updated_socket} =
        UserOnMountHooks.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user.id == user.id
    end

    test "redirects to login page if there isn't a valid user_token", %{conn: conn} do
      user_token = "invalid_token"
      session = conn |> put_session(:user_token, user_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: StratesWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} =
        UserOnMountHooks.on_mount(:ensure_authenticated, %{}, session, socket)

      assert updated_socket.assigns.current_user == nil
    end

    test "redirects to login page if there isn't a user_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: StratesWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} =
        UserOnMountHooks.on_mount(:ensure_authenticated, %{}, session, socket)

      assert updated_socket.assigns.current_user == nil
    end
  end

  describe "on_mount :redirect_if_user_is_authenticated" do
    test "redirects if there is an authenticated  user ", %{conn: conn, user: user} do
      user_token = Accounts.generate_session_token(user)
      session = conn |> put_session(:user_token, user_token) |> get_session()

      assert {:halt, _updated_socket} =
               UserOnMountHooks.on_mount(
                 :redirect_if_user_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated user", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               UserOnMountHooks.on_mount(
                 :redirect_if_user_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end
end

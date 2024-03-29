defmodule StratesWeb.UserOnMountHooks do
  @moduledoc false
  use StratesWeb, :verified_routes

  alias Strates.Accounts

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:maybe_assign_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule StratesWeb.PageLive do
        use StratesWeb, :live_view

        on_mount {StratesWeb.UserOnMountHooks, :maybe_assign_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{StratesWeb.UserOnMountHooks, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:maybe_assign_user, _params, session, socket) do
    {:cont, maybe_assign_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = maybe_assign_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/auth/login")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = maybe_assign_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp maybe_assign_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      get_user(session["user_token"])
    end)
  end

  defp signed_in_path(_conn), do: ~p"/"

  defp get_user(nil), do: nil
  defp get_user(token), do: Accounts.get_user_by_session_token(token)
end

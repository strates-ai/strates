defmodule StratesWeb.AuthRoutes do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      scope "/auth", StratesWeb do
        pipe_through [:browser]

        delete "/logout", UserSessionController, :delete

        live_session :current_user,
          on_mount: [{StratesWeb.UserOnMountHooks, :maybe_assign_user}] do
          live "/confirm/:token", UserConfirmationLive, :edit
          live "/confirm", UserConfirmationInstructionsLive, :new
        end
      end

      scope "/auth", StratesWeb do
        pipe_through [:browser, :redirect_if_user_is_authenticated]

        live_session :redirect_if_user_is_authenticated,
          on_mount: [{StratesWeb.UserOnMountHooks, :redirect_if_user_is_authenticated}] do
          live "/register", UserRegistrationLive, :new
          live "/login", UserLoginLive, :new
          live "/reset-password", UserForgotPasswordLive, :new
          live "/reset-password/:token", UserResetPasswordLive, :edit
        end

        post "/login", UserSessionController, :create
      end
    end
  end
end

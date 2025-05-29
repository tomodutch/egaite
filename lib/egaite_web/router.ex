defmodule EgaiteWeb.Router do
  use EgaiteWeb, :router
  import PhoenixStorybook.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EgaiteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_player
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    storybook_assets()
  end

  scope "/", EgaiteWeb do
    pipe_through :browser
    live_storybook("/storybook", backend_module: EgaiteWeb.Storybook)

    live_session :default, on_mount: [EgaiteWeb.InitAssigns] do
      live "/games/create", GameCreateLive
      live "/games/not-found", GameNotFoundLive
      live "/games/:id", GameLive
      live "/", GamesListLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", EgaiteWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:egaite, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EgaiteWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp put_player(conn, _opts) do
    case get_session(conn, "player") do
      nil ->
        player = %{
          "id" => Ecto.UUID.generate(),
          "name" => random_name()
        }

        put_session(conn, "player", player)

      _existing ->
        conn
    end
  end

  defp random_name do
    adjectives = ["Swift", "Clever", "Brave", "Witty", "Mighty", "Sneaky"]
    animals = ["Fox", "Tiger", "Owl", "Bear", "Eagle", "Panther"]
    "#{Enum.random(adjectives)}#{Enum.random(animals)}"
  end
end

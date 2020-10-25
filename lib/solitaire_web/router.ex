defmodule SolitaireWeb.Router do
  use SolitaireWeb, :router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {SolitaireWeb.LayoutView, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SolitaireWeb do
    pipe_through :browser

    # get "/", PageController, :index
    live "/", GameLive
    get "/can_move", PageController, :can_move
  end

  # Other scopes may use custom stacks.
  # scope "/api", SolitaireWeb do
  #   pipe_through :api
  # end
end

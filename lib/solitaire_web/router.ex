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

    live "/", GameLive
    get "/can_move", PageController, :can_move
    get "/get_unique_token", PageController, :get_unique_token
  end
end

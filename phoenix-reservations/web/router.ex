defmodule Reservations.Router do
  use Reservations.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Reservations do
    pipe_through :browser # Use the default browser stack

    resources "/", EventController
  end

  # Other scopes may use custom stacks.
  # scope "/api", Reservations do
  #   pipe_through :api
  # end
end

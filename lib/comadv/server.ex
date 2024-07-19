defmodule Comadv.Server do
  use GenServer

  def init({:started, width, height}) do
    {:ok, {width, height, :started}}
  end

  def handle_call(:current_state, _, {width, height, :started}) do
    {:reply, {width, height}, {width, height, :game_in_progress}}
  end
end

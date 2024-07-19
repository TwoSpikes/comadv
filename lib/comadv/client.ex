defmodule Comadv.Player do
  defstruct x: 1,
            y: 1,
            dir: :down
end

defmodule Comadv.GameState do
  defstruct game_over: false,
            win: nil
end

defmodule Comadv.Client do
  @server Comadv.Server
  @tick 1000

  def main(width \\ 30, height \\ 20) do
    play(width, height)
  end

  def play(width, height) do
    GenServer.start_link(@server, {:started, width, height}, name: @server)

    {width, height} = GenServer.call(@server, :current_state)

    IO.puts("Welcome! width is: #{width}, height is: #{height}")

    world = Matrix.new(height, width)

    game_state = %Comadv.GameState{}
    player = %Comadv.Player{}

    game_state = Comadv.UI.init(width, height, game_state)

    schedule_next_tick()

    loop(game_state, width, height, world, player)
  end

  defp schedule_next_tick() do
    timer = Process.send_after(self(), :tick, @tick)
  end

  defp handle_key(%{x: x, y: y} = player, ?h) do
    %{player | x: x - 1, y: y, dir: :left}
  end
  defp handle_key(%{x: x, y: y} = player, ?j) do
    %{player | x: x, y: y + 1, dir: :down}
  end
  defp handle_key(%{x: x, y: y} = player, ?k) do
    %{player | x: x, y: y - 1, dir: :up}
  end
  defp handle_key(%{x: x, y: y} = player, ?l) do
    %{player | x: x + 1, y: y, dir: :right}
  end
  defp handle_key(player, _) do
    player
  end

  defp turn(width, height, game_state, player, key) do
    next_player = handle_key(player, key)
    next_position = {next_player.x, next_player.y}

    cond do
      loses(width, height, next_position) ->
        {player, %Comadv.GameState{game_state | game_over: true}}

      true ->
        {move(next_player, next_position), game_state}
    end
  end

  defp move(player, {x, y} = _pos) do
    %{player | x: x, y: y}
  end

  defp loses(width, height, pos) do
    hits_wall(width, height, pos)
  end

  defp hits_wall(_width, _height, {0, _y}), do: true
  defp hits_wall(_width, _height, {_x, 0}), do: true
  defp hits_wall(width, _height, {x, _y}) when x == width - 1, do: true
  defp hits_wall(_width, height, {_x, y}) when y == height - 2, do: true
  defp hits_wall(_width, _height, _pos), do: false

  defp next_state(player, game_state) do
    {player, game_state}
  end

  defp loop(game_state, width, height, world, player) do
    {player, game_state} =
      receive do
        {:ex_ncurses, :key, key} ->
          {player, game_state} = turn(width, height, game_state, player, key)
          Comadv.UI.draw(width, height, player, game_state)
          {player, game_state}

        :tick ->
          {player, game_state} = next_state(player, game_state)
          Comadv.UI.draw(width, height, player, game_state)
          schedule_next_tick()
          {player, game_state}
      end

    if game_state.game_over != true do
      loop(game_state, width, height, world, player)
    else
      ExNcurses.move(height, 0)
      ExNcurses.addstr("Game over!")
      ExNcurses.refresh()
    end
  end
end

defmodule Comadv.Player do
  defstruct x: 1,
            y: 1,
            dir: :down
end

defmodule Comadv.GameState do
  defstruct game_over: false,
            win: nil,
            msg: ""
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
    _timer = Process.send_after(self(), :tick, @tick)
  end

  defp handle_key(_width, _height, %{x: x, y: y} = player, ?h, game_state, world) do
    {%{player | x: x - 1, y: y, dir: :left}, game_state, world}
  end
  defp handle_key(_width, _height, %{x: x, y: y} = player, ?j, game_state, world) do
    {%{player | x: x, y: y + 1, dir: :down}, game_state, world}
  end
  defp handle_key(_width, _height, %{x: x, y: y} = player, ?k, game_state, world) do
    {%{player | x: x, y: y - 1, dir: :up}, game_state, world}
  end
  defp handle_key(_width, _height,%{x: x, y: y} = player, ?l, game_state, world) do
    {%{player | x: x + 1, y: y, dir: :right}, game_state, world}
  end
  defp handle_key(_width, _height, %{x: x, y: y} = player, ?a, game_state, world) do
    {%{player | x: x - 1, y: y, dir: :left}, game_state, world}
  end
  defp handle_key(_width, _height, %{x: x, y: y} = player, ?s, game_state, world) do
    {%{player | x: x, y: y + 1, dir: :down}, game_state, world}
  end
  defp handle_key(_width, _height, %{x: x, y: y} = player, ?w, game_state, world) do
    {%{player | x: x, y: y - 1, dir: :up}, game_state, world}
  end
  defp handle_key(_width, _height,%{x: x, y: y} = player, ?d, game_state, world) do
    {%{player | x: x + 1, y: y, dir: :right}, game_state, world}
  end
  defp handle_key(width, height, %{x: x, y: y} = player, ?p, game_state, world) do
    {x, y} = pointing_to(player)
    if not hits_wall(width, height, {x, y}) do
      world = Matrix.set(world, y, x, "*")
      {player, game_state, world}
    else
      {player, game_state, world}
    end
  end
  defp handle_key(width, height, %{x: x, y: y} = player, ?x, game_state, world) do
    {x, y} = pointing_to(player)
    if not hits_wall(width, height, {x, y}) do
      world = Matrix.set(world, y, x, 0)
      {player, game_state, world}
    else
      {player, game_state, world}
    end
  end
  defp get_command(command) do
    receive do
      {:ex_ncurses, :key, c} ->
        case c do
          10 ->
            command
          7 ->
            ""
          127 ->
            if command != "" do
              ExNcurses.move(ExNcurses.gety(), ExNcurses.getx()-1)
              ExNcurses.addstr(" ")
              ExNcurses.move(ExNcurses.gety(), ExNcurses.getx()-1)
              ExNcurses.refresh()
              get_command(String.slice(command, 0..-2//1))
            else
              get_command("")
            end
          _ ->
            ExNcurses.addstr(to_string [c])
            ExNcurses.refresh()
            get_command("#{command}#{to_string [c]}")
        end
    end
  end
  defp handle_key(width, height, %{x: x, y: y} = player, ?/, game_state, world) do
    ExNcurses.move(height, 0)
    ExNcurses.addstr("/")
    ExNcurses.refresh()
    command = get_command("")
    case command do
      n when n in ["d","die"] ->
        {player, %{game_state | game_over: true}, world}
      _ ->
        {player, %{game_state | msg: "Unknown command: #{command}"}, world}
    end
  end
  defp handle_key(_width, _height, player, ?q, game_state, world) do
    {player, %{game_state | game_over: true}, world}
  end
  defp handle_key(_width, _height, player, _, game_state, world) do
    {player, game_state, world}
  end

  defp turn(width, height, game_state, player, key, world) do
    {next_player, game_state, world} = handle_key(width, height, player, key, game_state, world)
    next_position = {next_player.x, next_player.y}
    {x, y} = next_position
    next_cell = Matrix.elem(world, y, x)

    cond do
      loses(width, height, next_position) ->
        {player, %Comadv.GameState{game_state | game_over: true}, world}

      collide(next_position, next_cell) ->
        {player, game_state, world}

      true ->
        {move(next_player, next_position), game_state, world}
    end
  end

  defp move(player, {x, y} = _pos) do
    %{player | x: x, y: y}
  end

  defp loses(width, height, pos) do
    hits_wall(width, height, pos)
  end
  defp collide(pos, cell) do
    hits_block(pos, cell)
  end

  defp hits_wall(_width, _height, {0, _y}), do: true
  defp hits_wall(_width, _height, {_x, 0}), do: true
  defp hits_wall(width, _height, {x, _y}) when x == width - 1, do: true
  defp hits_wall(_width, height, {_x, y}) when y == height - 2, do: true
  defp hits_wall(_width, _height, _pos), do: false
  defp hits_block({x, y}, cell) do
    case cell do
      0 -> false
      _ -> true
    end
  end

  defp next_state(player, game_state, world) do
    {player, game_state, world}
  end

  defp pointing_to(%{x: x, y: y, dir: :left} = _player) do
    {x - 1, y}
  end
  defp pointing_to(%{x: x, y: y, dir: :right} = _player) do
    {x + 1, y}
  end
  defp pointing_to(%{x: x, y: y, dir: :down} = _player) do
    {x, y + 1}
  end
  defp pointing_to(%{x: x, y: y, dir: :up} = _player) do
    {x, y - 1}
  end
  defp game_over(height) do
    ExNcurses.move(height, 0)
    ExNcurses.addstr("Game over!")
    ExNcurses.refresh()
  end

  defp loop(game_state, width, height, world, player) do
    {player, game_state, world} =
      receive do
        {:ex_ncurses, :key, key} ->
          {player, game_state, world} = turn(width, height, game_state, player, key, world)
          Comadv.UI.draw(width, height, player, game_state, world)
          {player, game_state, world}

        :tick ->
          {player, game_state, world} = next_state(player, game_state, world)
          Comadv.UI.draw(width, height, player, game_state, world)
          schedule_next_tick()
          {player, game_state, world}
      end

    if game_state.game_over != true do
      loop(game_state, width, height, world, player)
    else
      game_over(height)
    end
  end
end

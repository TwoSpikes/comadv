defmodule Comadv.UI do
  def init(width, height, game_state) do
    ExNcurses.initscr()
    win = ExNcurses.newwin(height - 1, width, 1, 0)
    ExNcurses.listen()
    ExNcurses.noecho()
    ExNcurses.keypad()
    #ExNcurses.raw()
    ExNcurses.curs_set(0)

    %{game_state | win: win}
  end

  defp draw_world(world, win) do
    for {line, i} <- Enum.with_index(world) do
      for {cell, j} <- Enum.with_index(line) do
        if cell != 0 do
          ExNcurses.wmove(win, i, j)
          ExNcurses.waddstr(win, cell)
        end
      end
    end
  end

  defp draw_player(%{x: x, y: y, dir: :left}, win) do
    ExNcurses.wmove(win, y, x)
    ExNcurses.waddstr(win, "<")
  end
  defp draw_player(%{x: x, y: y, dir: :down}, win) do
    ExNcurses.wmove(win, y, x)
    ExNcurses.waddstr(win, "v")
  end
  defp draw_player(%{x: x, y: y, dir: :up}, win) do
    ExNcurses.wmove(win, y, x)
    ExNcurses.waddstr(win, "^")
  end
  defp draw_player(%{x: x, y: y, dir: :right}, win) do
    ExNcurses.wmove(win, y, x)
    ExNcurses.waddstr(win, ">")
  end

  def draw(_width, height, player, game_state, world) do
    ExNcurses.clear()
    ExNcurses.mvaddstr(0, 2, "Comadv")
    ExNcurses.wclear(game_state.win)
    ExNcurses.wborder(game_state.win)
    draw_world(world, game_state.win)
    draw_player(player, game_state.win)
    ExNcurses.move(height, 0)
    ExNcurses.addstr(game_state.msg)
    ExNcurses.refresh()
    ExNcurses.wrefresh(game_state.win)
  end
end

defmodule Comadv do
  def run(width \\ 30, height \\ 20) do
    Comadv.Client.play(width, height)
  end
end

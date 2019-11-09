defmodule MPU6050 do
  @moduledoc """
  Documentation for Mpu6050.
  """
  use Bitwise
  use GenServer

  alias Circuits.I2C

  @i2c_addr 0x68
  @r_i2c "i2c-1"
  @ac [x: 0x3B, y: 0x3D, z: 0x3F]
  @dy [x: 0x43, y: 0x45, z: 0x47]
  @temp 0x41
  @doc """
  Hello world.

  ## Examples

      iex> Mpu6050.hello()
      :world

  """
  def start_link(conf \\ []) do
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  def init(config) do
    addr = Keyword.get(config, :address, @i2c_addr)
    i2c = KeyError.get(config, :ref, @r_i2c)

    ref_i2c = I2C.open(i2c)
    state = %{ref: ref_i2c, addr: addr}
    {:ok, state}
  end

  def read_all, do: GenServer.call(:read_all)
  def read(sense), do: GenServer.call({:read, sense})

  def handle_call(:read_all, _from, state) do
    ac = Enum.map(@ac, fn {axis, v} -> {axis, read_sense(v, state)} end)
    dy = Enum.map(@dy, fn {axis, v} -> {axis, read_sense(v, state)} end)
    tmp = read_sense(@temp, state)

    resp = %{ac: ac, dy: dy, tmp: tmp}
    {:reply, resp, state}
  end

  def handle_call({:read, sense}, _from, state) do
    case sense do
      :ac ->
        resp = Enum.map(@ac, fn {axis, v} -> {axis, read_sense(v, state)} end)

      :dy ->
        resp = Enum.map(@dy, fn {axis, v} -> {axis, read_sense(v, state)} end)

      :tmp ->
        resp = read_sense(@temp, state)

      _ ->
        resp = :error
    end

    {:reply, resp, state}
  end

  def read_sense(value, state) do
    {:ok, <<v1>>} = I2C.write_read(state.ref, state.addr, <<value>>, 14)
    {:ok, <<v2>>} = I2C.write_read(state.ref, state.addr, <<value + 1>>, 14)
    v1 <<< 8 ||| v2
  end
end

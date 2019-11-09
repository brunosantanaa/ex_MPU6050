defmodule Mpu6050Test do
  use ExUnit.Case
  doctest Mpu6050

  test "greets the world" do
    assert Mpu6050.hello() == :world
  end
end

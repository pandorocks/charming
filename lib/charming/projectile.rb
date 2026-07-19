# frozen_string_literal: true

module Charming
  # Projectile is simple physics motion for games: a position advanced by a
  # velocity, and a velocity advanced by an acceleration (typically gravity),
  # one fixed time step per frame (semi-implicit Euler, matching
  # charmbracelet/harmonica's projectile):
  #
  #   ball = Charming::Projectile.new(
  #     delta_time: Charming.fps(60),
  #     position: Charming::Projectile::Point.new(x: 0.0, y: 0.0),
  #     velocity: Charming::Projectile::Vector.new(x: 20.0, y: 0.0),
  #     acceleration: Charming::Projectile::TERMINAL_GRAVITY
  #   )
  #   position = ball.update  # each frame
  class Projectile
    Point = Data.define(:x, :y, :z) do
      def initialize(x:, y:, z: 0.0)
        super
      end
    end

    Vector = Data.define(:x, :y, :z) do
      def initialize(x:, y:, z: 0.0)
        super
      end
    end

    # Gravity for a coordinate plane whose origin is bottom-left (y grows upward).
    GRAVITY = Vector.new(x: 0.0, y: -9.81)

    # Gravity for terminal coordinates, whose origin is top-left (y grows downward).
    TERMINAL_GRAVITY = Vector.new(x: 0.0, y: 9.81)

    attr_reader :position, :velocity, :acceleration

    def initialize(delta_time:, position:, velocity: Vector.new(x: 0.0, y: 0.0), acceleration: Vector.new(x: 0.0, y: 0.0))
      @delta_time = delta_time
      @position = position
      @velocity = velocity
      @acceleration = acceleration
    end

    # Advances one frame and returns the new position. Position moves by the
    # current velocity before the velocity accelerates — keep this order.
    def update
      @position = shift(position, velocity)
      @velocity = shift(velocity, acceleration)
      position
    end

    private

    attr_reader :delta_time

    def shift(value, rate)
      value.with(
        x: value.x + rate.x * delta_time,
        y: value.y + rate.y * delta_time,
        z: value.z + rate.z * delta_time
      )
    end
  end
end

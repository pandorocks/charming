# frozen_string_literal: true

module DemoApp
  # Demonstrates physics-based animation: a spring-driven ball on a track. The
  # `animate` timer starts stopped, `bounce` kicks off motion, and `step_slide`
  # stops the timer again once the spring settles — the canonical pattern for
  # zero-cost idle animation.
  class PhysicsController < ApplicationController
    SPRING = Charming::Spring.new(delta_time: Charming.fps(60), angular_frequency: 6.0, damping_ratio: 0.5)

    animate :slide, fps: 60, action: :step_slide
    key "b", :bounce, scope: :content

    def show
      render_physics
    end

    def bounce
      physics.target_x = (physics.target_x > 20.0) ? 2.0 : 40.0
      start_timer(:slide)
      render_physics
    end

    def step_slide
      physics.x, physics.velocity = SPRING.update(physics.x, physics.velocity, physics.target_x)
      settle if SPRING.settled?(physics.x, physics.velocity, physics.target_x, epsilon: 0.5)
      render_physics
    end

    private

    def physics
      state(:physics, PhysicsState)
    end

    def settle
      physics.x = physics.target_x
      physics.velocity = 0.0
      stop_timer(:slide)
    end

    def render_physics
      render :show, physics: physics, running: timer_running?(:slide), palette: command_palette
    end
  end
end

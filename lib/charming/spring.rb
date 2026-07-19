# frozen_string_literal: true

# ******************************************************************************
#
#  Copyright (c) 2008-2012 Ryan Juckett
#  http://www.ryanjuckett.com/
#
#  This software is provided 'as-is', without any express or implied
#  warranty. In no event will the authors be held liable for any damages
#  arising from the use of this software.
#
#  Permission is granted to anyone to use this software for any purpose,
#  including commercial applications, and to alter it and redistribute it
#  freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#     claim that you wrote the original software. If you use this software
#     in a product, an acknowledgment in the product documentation would be
#     appreciated but is not required.
#
#  2. Altered source versions must be plainly marked as such, and must not be
#     misrepresented as being the original software.
#
#  3. This notice may not be removed or altered from any source
#     distribution.
#
# ******************************************************************************
#
#  Ported to Go by Charmbracelet, Inc. in 2021 (charmbracelet/harmonica, MIT).
#  Ported to Ruby for Charming in 2026 from charmbracelet/harmonica.
#
#  For background on the algorithm see:
#  https://www.ryanjuckett.com/damped-springs/

module Charming
  # Spring is a damped harmonic oscillator for physics-based animation. It
  # precomputes motion coefficients for a fixed time step so each frame update
  # is four multiply-adds. Instances are immutable; the caller owns position
  # and velocity (typically as Float attributes on an ApplicationState) and
  # feeds them back in every frame:
  #
  #   SPRING = Charming::Spring.new(delta_time: Charming.fps(60))
  #   position, velocity = SPRING.update(position, velocity, target)
  #
  # The damping ratio shapes the motion: below 1 overshoots and oscillates,
  # exactly 1 reaches the target as fast as possible without overshooting,
  # above 1 approaches slower still. Angular frequency scales the speed.
  class Spring
    def initialize(delta_time:, angular_frequency: 6.0, damping_ratio: 0.5)
      angular_frequency = [0.0, angular_frequency].max
      damping_ratio = [0.0, damping_ratio].max
      @pos_pos, @pos_vel, @vel_pos, @vel_vel =
        coefficients(delta_time, angular_frequency, damping_ratio)
      freeze
    end

    # Advances one frame toward *target*, returning `[new_position, new_velocity]`.
    def update(position, velocity, target)
      relative = position - target
      [relative * @pos_pos + velocity * @pos_vel + target,
        relative * @vel_pos + velocity * @vel_vel]
    end

    # True once the motion has effectively come to rest at *target* — the guard
    # for stopping an animation timer.
    def settled?(position, velocity, target, epsilon: 0.01)
      (position - target).abs < epsilon && velocity.abs < epsilon
    end

    private

    def coefficients(delta_time, frequency, ratio)
      return [1.0, 0.0, 0.0, 1.0] if frequency < Float::EPSILON

      if ratio > 1.0 + Float::EPSILON
        over_damped(delta_time, frequency, ratio)
      elsif ratio < 1.0 - Float::EPSILON
        under_damped(delta_time, frequency, ratio)
      else
        critically_damped(delta_time, frequency)
      end
    end

    def over_damped(delta_time, frequency, ratio)
      za = -frequency * ratio
      zb = frequency * Math.sqrt(ratio * ratio - 1.0)
      z1 = za - zb
      z2 = za + zb
      e2 = Math.exp(z2 * delta_time)
      e1_over_two_zb = Math.exp(z1 * delta_time) / (2.0 * zb)
      e2_over_two_zb = e2 / (2.0 * zb)
      z1e1_over_two_zb = z1 * e1_over_two_zb
      z2e2_over_two_zb = z2 * e2_over_two_zb

      [e1_over_two_zb * z2 - z2e2_over_two_zb + e2,
        -e1_over_two_zb + e2_over_two_zb,
        (z1e1_over_two_zb - z2e2_over_two_zb + e2) * z2,
        -z1e1_over_two_zb + z2e2_over_two_zb]
    end

    def under_damped(delta_time, frequency, ratio)
      omega_zeta = frequency * ratio
      alpha = frequency * Math.sqrt(1.0 - ratio * ratio)
      exp_term = Math.exp(-omega_zeta * delta_time)
      exp_sin = exp_term * Math.sin(alpha * delta_time)
      exp_cos = exp_term * Math.cos(alpha * delta_time)
      exp_omega_zeta_sin_over_alpha = omega_zeta * exp_sin / alpha

      [exp_cos + exp_omega_zeta_sin_over_alpha,
        exp_sin / alpha,
        -exp_sin * alpha - omega_zeta * exp_omega_zeta_sin_over_alpha,
        exp_cos - exp_omega_zeta_sin_over_alpha]
    end

    def critically_damped(delta_time, frequency)
      exp_term = Math.exp(-frequency * delta_time)
      time_exp = delta_time * exp_term
      time_exp_freq = time_exp * frequency

      [time_exp_freq + exp_term,
        time_exp,
        -frequency * time_exp_freq,
        -time_exp_freq + exp_term]
    end
  end
end

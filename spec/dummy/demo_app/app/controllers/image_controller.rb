# frozen_string_literal: true

module DemoApp
  # Demonstrates Charming::Components::Image. The Source is kept in `session` so its one-time
  # transmit fires once and survives re-renders, mirroring how the audio player is held.
  class ImageController < ApplicationController
    key "c", :copy_path, scope: :content

    def show
      set_title("DemoApp — Image")
      render :show, image: sample_image, palette: command_palette
    end

    # Demonstrates the imperative terminal helpers: copies the image path to the system clipboard,
    # rings the bell, and raises a desktop notification — all out-of-band, alongside a normal render.
    def copy_path
      copy(sample_image_path)
      bell
      notify("Copied image path to clipboard", title: "DemoApp")
      render :show, image: sample_image, palette: command_palette
    end

    private

    def sample_image
      session[:sample_image] ||= Charming::Image::Source.new(path: sample_image_path)
    end

    def sample_image_path
      File.join(application.class.root, "assets", "dusk-guardian.png")
    end
  end
end

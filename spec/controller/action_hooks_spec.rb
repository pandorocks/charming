# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Charming::Controller action hooks" do
  let(:app) { Charming::Application.new }
  let(:screen) { Charming::Screen.new(width: 80, height: 24) }

  def build_controller(klass)
    klass.new(application: app, screen: screen, route: nil)
  end

  describe "before_action" do
    let(:ctrl_class) do
      Class.new(Charming::Controller) do
        attr_reader :log

        before_action :set_log
        before_action :set_second, only: [:show]
        before_action :set_third, except: [:show]

        def show
          render("show:#{@log}")
        end

        def other
          render("other:#{@log}")
        end

        private

        def set_log = (@log = "before")
        def set_second = (@log += "+second")
        def set_third = (@log += "+third")
      end
    end

    it "runs before_action before the action" do
      ctrl = build_controller(ctrl_class)
      response = ctrl.dispatch(:show)
      expect(response.body).to include("before")
    end

    it "runs only: filter for matching actions" do
      ctrl = build_controller(ctrl_class)
      response = ctrl.dispatch(:show)
      expect(response.body).to include("second")
    end

    it "does not run only: filter for non-matching actions" do
      ctrl = build_controller(ctrl_class)
      response = ctrl.dispatch(:other)
      expect(response.body).not_to include("second")
    end

    it "runs except: filter for non-excluded actions" do
      ctrl = build_controller(ctrl_class)
      response = ctrl.dispatch(:other)
      expect(response.body).to include("third")
    end

    it "does not run except: filter for excluded actions" do
      ctrl = build_controller(ctrl_class)
      response = ctrl.dispatch(:show)
      expect(response.body).not_to include("third")
    end
  end

  describe "after_action" do
    let(:ctrl_class) do
      Class.new(Charming::Controller) do
        after_action :append_after

        def show
          @body = "action"
          render(@body)
        end

        private

        def append_after = (@body = "#{@body}+after")
      end
    end

    it "runs after_action after the action" do
      ctrl = build_controller(ctrl_class)
      ctrl.dispatch(:show)
      expect(ctrl.instance_variable_get(:@body)).to eq("action+after")
    end
  end

  describe "around_action" do
    let(:ctrl_class) do
      Class.new(Charming::Controller) do
        around_action :wrap

        def show
          render("action")
        end

        private

        def wrap
          @order = "before>"
          yield
          @order += "<after"
        end
      end
    end

    it "wraps the action" do
      ctrl = build_controller(ctrl_class)
      ctrl.dispatch(:show)
      expect(ctrl.instance_variable_get(:@order)).to eq("before><after")
    end
  end

  describe "rescue_from" do
    let(:ctrl_class) do
      Class.new(Charming::Controller) do
        rescue_from ArgumentError, with: :handle_arg_error
        rescue_from StandardError, with: :handle_standard_error

        def show
          raise ArgumentError, "bad argument"
        end

        def explode
          raise "boom"
        end

        private

        def handle_arg_error(e)
          render("rescued ArgumentError: #{e.message}")
        end

        def handle_standard_error(e)
          render("rescued StandardError: #{e.message}")
        end
      end
    end

    it "catches the matching exception class" do
      ctrl = build_controller(ctrl_class)
      response = ctrl.dispatch(:show)
      expect(response.body).to include("rescued ArgumentError: bad argument")
    end

    it "catches a superclass exception via the hierarchy" do
      ctrl = build_controller(ctrl_class)
      response = ctrl.dispatch(:explode)
      expect(response.body).to include("rescued StandardError: boom")
    end

    it "re-raises when no handler matches" do
      klass = Class.new(Charming::Controller) do
        rescue_from ArgumentError, with: :noop
        def show = raise("unhandled")

        private

        def noop = nil
      end
      ctrl = build_controller(klass)
      expect { ctrl.dispatch(:show) }.to raise_error(RuntimeError, "unhandled")
    end
  end

  describe "inheritance" do
    let(:parent) do
      Class.new(Charming::Controller) do
        before_action :parent_hook
        def show = render("show")

        private

        def parent_hook = (@parent_ran = true)
      end
    end

    let(:child) do
      Class.new(parent) do
        before_action :child_hook

        private

        def child_hook = (@child_ran = true)
      end
    end

    it "inherits parent hooks" do
      ctrl = build_controller(child)
      ctrl.dispatch(:show)
      expect(ctrl.instance_variable_get(:@parent_ran)).to be true
    end

    it "runs child's own hooks" do
      ctrl = build_controller(child)
      ctrl.dispatch(:show)
      expect(ctrl.instance_variable_get(:@child_ran)).to be true
    end

    it "does not pollute parent's hook list" do
      expect(parent.action_hooks.length).to eq(1)
      expect(child.action_hooks.length).to eq(2)
    end
  end
end

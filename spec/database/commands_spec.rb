# frozen_string_literal: true

require "stringio"
require "tmpdir"

RSpec.describe Charming::Database::Commands do
  def cli(pwd, out: StringIO.new, err: StringIO.new)
    Charming::CLI.new(out: out, err: err, pwd: pwd)
  end

  def build_app(dir, name)
    cli(dir).call(["new", name, "--database", "sqlite3"])
    File.join(dir, name)
  end

  describe "Charming.env" do
    after { Charming.env = nil }

    it "defaults to development" do
      Charming.env = nil
      expect(Charming.env).to eq("development")
      expect(Charming.env.development?).to be true
    end

    it "can be overridden" do
      Charming.env = "test"
      expect(Charming.env.test?).to be true
      expect(Charming.env.production?).to be false
    end
  end

  describe "environment-aware database config" do
    it "writes a config that selects the database file by CHARMING_ENV" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "env_cfg_tui")
        config = File.read(File.join(app_root, "config", "database.rb"))
        expect(config).to include('ENV["CHARMING_ENV"] || "development"')
        expect(config).to include("db/\#{environment}.sqlite3")
      end
    end

    it "creates the test database when CHARMING_ENV=test" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "env_test_tui")
        original = ENV["CHARMING_ENV"]
        ENV["CHARMING_ENV"] = "test"

        output = StringIO.new
        cli(app_root, out: output).call(%w[db:create])

        expect(output.string).to include("create db/test.sqlite3")
        expect(File).to exist(File.join(app_root, "db", "test.sqlite3"))
        expect(File).not_to exist(File.join(app_root, "db", "development.sqlite3"))
      ensure
        ENV["CHARMING_ENV"] = original
      end
    end
  end

  describe "db:setup" do
    it "creates, migrates, and seeds in one command" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "setup_tui")
        cli(app_root).call(%w[g model widget label:string])
        File.write(File.join(app_root, "db", "seeds.rb"), <<~RUBY)
          # frozen_string_literal: true
          SetupTui::Widget.create!(label: "seeded")
        RUBY

        output = StringIO.new
        status = cli(app_root, out: output).call(%w[db:setup])

        expect(status).to eq(0)
        expect(output.string).to include("create db/development.sqlite3")
        expect(output.string).to include("seed db/seeds.rb")
        expect(output.string).to include("setup db/development.sqlite3")
        expect(File).to exist(File.join(app_root, "db", "schema.rb"))
      end
    end
  end

  describe "db:status and db:version" do
    it "prints the migration status table" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "status_tui")
        cli(app_root).call(%w[g model gadget label:string])
        cli(app_root).call(%w[db:migrate])

        output = StringIO.new
        status = cli(app_root, out: output).call(%w[db:status])

        expect(status).to eq(0)
        expect(output.string).to include("Status")
        expect(output.string).to include("up")
        expect(output.string).to include("Create gadgets")
      end
    end

    it "prints the current schema version" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "version_tui")
        cli(app_root).call(%w[g model sprocket label:string])
        cli(app_root).call(%w[db:migrate])

        output = StringIO.new
        status = cli(app_root, out: output).call(%w[db:version])

        expect(status).to eq(0)
        expect(output.string).to match(/version \d{14}/)
      end
    end
  end

  describe "db:schema:dump and db:schema:load" do
    it "round-trips the schema" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "schema_tui")
        cli(app_root).call(%w[g model cog label:string])
        cli(app_root).call(%w[db:migrate])

        schema_path = File.join(app_root, "db", "schema.rb")
        expect(File).to exist(schema_path)
        expect(File.read(schema_path)).to include("create_table \"cogs\"")

        # Drop and reload purely from schema
        cli(app_root).call(%w[db:drop])
        create_out = StringIO.new
        cli(app_root, out: create_out).call(%w[db:create])
        load_out = StringIO.new
        load_status = cli(app_root, out: load_out).call(%w[db:schema:load])

        expect(load_status).to eq(0)
        expect(load_out.string).to include("load db/schema.rb")
        expect(ActiveRecord::Base.connection.table_exists?("cogs")).to be true
      end
    end
  end

  describe "db:rollback with STEP" do
    it "rolls back multiple migrations" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "rollback_tui")
        cli(app_root).call(%w[g model alpha label:string])
        sleep 1 # distinct migration timestamps
        cli(app_root).call(%w[g model beta label:string])
        cli(app_root).call(%w[db:migrate])

        output = StringIO.new
        status = cli(app_root, out: output).call(%w[db:rollback STEP=2])

        expect(status).to eq(0)
        expect(output.string).to include("rollback db/migrate (2 steps)")
        expect(ActiveRecord::Base.connection.table_exists?("alphas")).to be false
        expect(ActiveRecord::Base.connection.table_exists?("betas")).to be false
      end
    end

    it "rejects non-positive STEP values" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "badstep_tui")
        error = StringIO.new
        status = cli(app_root, err: error).call(%w[db:rollback STEP=0])

        expect(status).to eq(1)
        expect(error.string).to include("STEP must be a positive integer")
      end
    end
  end

  describe "db:prepare" do
    it "sets up a fresh database when none exists" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "prepare_tui")
        cli(app_root).call(%w[g model lever label:string])

        output = StringIO.new
        status = cli(app_root, out: output).call(%w[db:prepare])

        expect(status).to eq(0)
        expect(File).to exist(File.join(app_root, "db", "development.sqlite3"))
        expect(ActiveRecord::Base.connection.table_exists?("levers")).to be true
      end
    end
  end

  describe "migration generator" do
    it "generates a create_table migration from the name convention" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "mig_create_tui")
        output = StringIO.new

        status = cli(app_root, out: output).call(%w[g migration create_posts title:string body:text])

        expect(status).to eq(0)
        migration = Dir.glob(File.join(app_root, "db/migrate/*_create_posts.rb")).first
        expect(migration).not_to be_nil
        content = File.read(migration)
        expect(content).to include("class CreatePosts < ActiveRecord::Migration[8.1]")
        expect(content).to include("create_table :posts")
        expect(content).to include("t.string :title")
        expect(content).to include("t.text :body")
        expect(content).to include("t.timestamps")
      end
    end

    it "generates add_column lines from the add_x_to_y convention" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "mig_add_tui")

        cli(app_root).call(%w[g migration add_email_to_users email:string])

        migration = Dir.glob(File.join(app_root, "db/migrate/*_add_email_to_users.rb")).first
        expect(File.read(migration)).to include("add_column :users, :email, :string")
      end
    end

    it "generates remove_column lines from the remove_x_from_y convention" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "mig_remove_tui")

        cli(app_root).call(%w[g migration remove_email_from_users email:string])

        migration = Dir.glob(File.join(app_root, "db/migrate/*_remove_email_from_users.rb")).first
        expect(File.read(migration)).to include("remove_column :users, :email, :string")
      end
    end

    it "generates an empty change method for unrecognized names" do
      Dir.mktmpdir do |dir|
        app_root = build_app(dir, "mig_empty_tui")

        cli(app_root).call(%w[g migration tune_indexes])

        migration = Dir.glob(File.join(app_root, "db/migrate/*_tune_indexes.rb")).first
        expect(File.read(migration)).to include("# Add your migration steps here.")
      end
    end

    it "rejects migration generation without database support" do
      Dir.mktmpdir do |dir|
        cli(dir).call(%w[new plain_tui])
        app_root = File.join(dir, "plain_tui")
        error = StringIO.new

        status = cli(app_root, err: error).call(%w[g migration create_posts])

        expect(status).to eq(1)
        expect(error.string).to include("Database support is not configured")
      end
    end
  end
end

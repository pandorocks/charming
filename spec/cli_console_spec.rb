# frozen_string_literal: true

require "stringio"
require "tmpdir"

RSpec.describe "Charming CLI extras" do
  describe "charming console" do
    it "errors helpfully outside an app root" do
      Dir.mktmpdir do |dir|
        error = StringIO.new
        status = Charming::CLI.new(out: StringIO.new, err: error, pwd: dir).call(%w[console])

        expect(status).to eq(1)
        expect(error.string).to include("Run this command from a Charming app root")
      end
    end

    it "rejects extra arguments" do
      error = StringIO.new
      status = Charming::CLI.new(out: StringIO.new, err: error, pwd: Dir.pwd).call(%w[console extra])

      expect(status).to eq(1)
      expect(error.string).to include("Usage: charming console")
    end
  end

  describe "generated spec_helper" do
    it "is minimal for non-database apps" do
      Dir.mktmpdir do |dir|
        Charming::CLI.new(out: StringIO.new, pwd: dir).call(%w[new plain_helper_tui])
        helper = File.read(File.join(dir, "plain_helper_tui", "spec", "spec_helper.rb"))

        expect(helper).to include('require "plain_helper_tui"')
        expect(helper).not_to include("CHARMING_ENV")
        expect(helper).not_to include("ActiveRecord")
      end
    end

    it "pins the test environment and isolates the database for database apps" do
      Dir.mktmpdir do |dir|
        Charming::CLI.new(out: StringIO.new, pwd: dir).call(%w[new db_helper_tui --database sqlite3])
        helper = File.read(File.join(dir, "db_helper_tui", "spec", "spec_helper.rb"))

        expect(helper).to include('ENV["CHARMING_ENV"] ||= "test"')
        expect(helper).to include("load schema")
        expect(helper).to include("ActiveRecord::Base.transaction")
        expect(helper).to include("raise ActiveRecord::Rollback")
      end
    end
  end
end

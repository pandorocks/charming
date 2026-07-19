# frozen_string_literal: true

require "stringio"
require "tmpdir"

RSpec.describe Charming::Generators::AppGenerator do
  def generate(name, database: nil)
    Dir.mktmpdir do |dir|
      described_class.new(name, out: StringIO.new, destination: dir, database: database).generate
      yield File.join(dir, name)
    end
  end

  it "tells database apps to set up the database before running" do
    generate("diary", database: "sqlite3") do |app_root|
      readme = File.read(File.join(app_root, "README.md"))

      expect(readme).to include("bundle exec charming db:setup")
      expect(readme.index("db:setup")).to be < readme.index("bundle exec diary")
    end
  end

  it "keeps the README free of database steps for plain apps" do
    generate("diary") do |app_root|
      readme = File.read(File.join(app_root, "README.md"))

      expect(readme).not_to include("db:setup")
      expect(readme).to include("bundle exec diary")
    end
  end
end

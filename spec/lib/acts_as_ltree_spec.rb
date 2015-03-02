require 'spec_helper'

RSpec.describe ActsAsLtree do
  with_model :Tag do
    table do |t|
      t.ltree :path
    end

    model do
      acts_as_ltree
    end
  end

  let!(:programming)   { Tag.create path: 'programming' }
  let!(:ruby)          { Tag.create path: 'programming.ruby' }
  let!(:rspec)         { Tag.create path: 'programming.ruby.rspec' }
  let!(:ruby_on_rails) { Tag.create path: 'programming.ruby.ruby_on_rails' }
  let!(:sinatra)       { Tag.create path: 'programming.ruby.ruby_on_rails.sinatra' }
  let!(:rspec_rails)   { Tag.create path: 'programming.ruby.ruby_on_rails.rspec' }
  let!(:compsci)       { Tag.create path: 'programming.computer_science' }

  describe "children" do
    it "fetches proper results" do
      expect(programming.children).to contain_exactly(ruby, compsci)
      expect(ruby.children).to contain_exactly(ruby_on_rails, rspec)
      expect(ruby_on_rails.children).to contain_exactly(sinatra, rspec_rails)
    end

    it "allows traversing" do
      results = programming.children.flat_map do |tag1|
        [tag1] + tag1.children.flat_map do |tag2|
          [tag2] + tag2.children
        end
      end
      expect(results).to contain_exactly(ruby, ruby_on_rails, rspec, sinatra, rspec_rails, compsci)
    end
  end

  describe "ancestors" do
    it "fetches proper results" do
      expect(ruby.ancestors).to contain_exactly(ruby_on_rails, rspec, sinatra, rspec_rails)
    end
  end
end

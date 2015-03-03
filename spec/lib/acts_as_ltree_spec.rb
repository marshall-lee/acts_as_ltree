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

  describe "instance methods" do
    subject { Tag.new }

    it { should respond_to(:descendants) }
    it { should respond_to(:children) }
    it { should respond_to(:new_child) }
    it { should respond_to(:create_child) }
  end

  describe "class methods" do
    subject { Tag }

    it { should respond_to(:descendants_of) }
    it { should respond_to(:ancestors_of) }
    it { should respond_to(:matching_lquery) }
    it { should respond_to(:matching_ltxtquery) }
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

  describe "descendants" do
    it "fetches proper results" do
      expect(ruby.descendants).to contain_exactly(ruby_on_rails, rspec, sinatra, rspec_rails)
    end
  end

  describe "children creation method" do
    it "creates and saves child object" do
      expect(programming.create_child(leaf_label: 'lambda')).to be_persisted
    end

    it "matches proper path" do
      expect(programming.create_child(leaf_label: 'lambda').path).to eq('programming.lambda')
    end
  end

  describe "new children making method" do
    it "creates new child without saving" do
      expect(programming.new_child(leaf_label: 'lambda')).to be_new_record
    end

    it "matches proper path" do
      expect(programming.new_child(leaf_label: 'lambda').path).to eq('programming.lambda')
    end
  end

  describe "scope" do
    describe "descendants_of" do
      it "fetches proper results" do
        expect(Tag.descendants_of('programming.ruby.ruby_on_rails')).to contain_exactly(ruby_on_rails, sinatra, rspec_rails)
      end
    end

    describe "ancestors_of" do
      it "fetches proper results" do
        expect(Tag.ancestors_of('programming.ruby.ruby_on_rails')).to contain_exactly(ruby_on_rails, ruby, programming)
      end
    end

    describe "matching_lquery" do
      it "fetches proper results" do
        expect(Tag.matching_lquery('*.rspec.*')).to contain_exactly(rspec, rspec_rails)
        expect(Tag.matching_lquery('*.!ruby_on_rails.*.rspec.*')).to contain_exactly(rspec)
      end
    end

    describe "matching_ltxtquery" do
      it "fetches proper results" do
        expect(Tag.matching_ltxtquery('!ruby_on_rails & programming & ruby')).to contain_exactly(ruby, rspec)
      end
    end
  end
end

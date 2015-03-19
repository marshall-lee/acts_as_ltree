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
    it { should respond_to(:self_and_descendants) }
    it { should respond_to(:strict_descendants) }
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

  describe "self_and_descendants" do
    it "fetches proper results" do
      expect(ruby.self_and_descendants).to contain_exactly(ruby, ruby_on_rails, rspec, sinatra, rspec_rails)
    end
  end

  describe "strict_descendants" do
    it "fetches proper results" do
      expect(ruby.strict_descendants).to contain_exactly(ruby_on_rails, rspec, sinatra, rspec_rails)
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
      let(:descendants) {
        Tag.descendants_of('programming.ruby.ruby_on_rails')
      }

      it "fetches proper results" do
        expect(descendants).to contain_exactly(ruby_on_rails, sinatra, rspec_rails)
      end

      describe "with min_depth" do
        let(:descendants) {
          Tag.descendants_of('programming', min_depth: 2)
        }

        it "fetches proper results" do
          expect(descendants).to contain_exactly(rspec, ruby_on_rails, rspec_rails, sinatra)
        end

        describe "when passing non-integer value" do
          it "raises proper exception" do
            expect {
              Tag.descendants_of('programming', min_depth: "2")
            }.to raise_error(ArgumentError)
          end
        end
      end

      describe "with max_depth" do
        let(:descendants) {
          Tag.descendants_of('programming', max_depth: 2)
        }

        it "fetches proper results" do
          expect(descendants).to contain_exactly(programming, ruby, rspec, ruby_on_rails, compsci)
        end

        describe "when passing non-integer value" do
          it "raises proper exception" do
            expect {
              Tag.descendants_of('programming', max_depth: "2")
            }.to raise_error(ArgumentError)
          end
        end
      end

      describe "with exact_depth" do
        let(:descendants) {
          Tag.descendants_of('programming', exact_depth: 1)
        }

        it "fetches proper results" do
          expect(descendants).to contain_exactly(ruby, compsci)
        end

        describe "when passing non-integer value" do
          it "raises proper exception" do
            expect {
              Tag.descendants_of('programming', exact_depth: "2")
            }.to raise_error(ArgumentError)
          end
        end

        describe "when using together with max_depth or min_depth" do
          it "raises proper exception" do
            expect {
              Tag.descendants_of('programming', min_depth: 3, exact_depth: 2)
            }.to raise_error(ArgumentError)
          end
        end
      end

      describe "with min and max depth" do
        let(:descendants) {
          Tag.descendants_of('programming', min_depth: 1, max_depth: 2)
        }

        it "fetches proper results" do
          expect(descendants).to contain_exactly(ruby, ruby_on_rails, rspec, compsci)
        end

        describe "when passing min_depth: false" do
          let(:descendants) {
            Tag.descendants_of('programming', min_depth: false, max_depth: 2)
          }

          it "actualy doesn't use min_depth" do
            expect(descendants).to contain_exactly(programming, ruby, ruby_on_rails, rspec, compsci)
          end
        end

        describe "when passing max_depth: false" do
          let(:descendants) {
            Tag.descendants_of('programming', min_depth: 2, max_depth: false)
          }

          it "actualy doesn't use max_depth" do
            expect(descendants).to contain_exactly(rspec, ruby_on_rails, rspec_rails, sinatra)
          end
        end
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

    describe "preload_descendants" do
      it "should return correctly proxied object" do
        expect(ruby.preload_descendants).to be_kind_of(Tag)
      end

      describe "fetching all descendants" do
        let(:programming_preloaded) {
          programming.preload_descendants
        }

        it "should fetch proper results" do
          expect(programming_preloaded.descendants).to contain_exactly(ruby, compsci, ruby_on_rails, rspec, sinatra, rspec_rails)
          expect(programming_preloaded.children).to contain_exactly(ruby, compsci)
        end

        describe "when traversing" do
          it "should execute only one query" do
            expect(ActiveRecord::Base.connection).to receive(:exec_query).once.and_call_original
            programming_preloaded.children.each do |tag|
              tag.children.each do |tag1|
                tag1.children.each { }
              end
            end
          end
        end
      end
    end
  end
end

require 'active_support/core_ext/array/access'

RSpec.describe BetterError do

  class FirstTestError < BetterError; end
  class SecondTestError < FirstTestError; end

  it "is an abstract call" do
    expect { BetterError.new }.to raise_error(StandardError)
    expect(FirstTestError.new).to be_truthy
  end

  describe "defaults" do
    subject(:error) { FirstTestError.new }

    specify "#id returns an UUID V4" do
      expect(error.id).to match(/^[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i)
    end

    specify ".pretty_error" do
      expect(error.class.pretty_name).to eq('First Test')
    end
  end

  describe ".create" do
    YetAnotherTestError = FirstTestError.create(pretty_name: 'So Pretty', id_generator: -> { 42 })

    subject(:error) { YetAnotherTestError.new }

    it "creates a subclass" do
      expect(error).to be_a(FirstTestError)
    end

    specify "#id" do
      expect(error.id).to eq(42)
    end

    specify ".pretty_name" do
      expect(error.class.pretty_name).to eq('So Pretty')
    end

    context "when inheriting from a subclass of BetterError" do
      AndAnotherTestError = YetAnotherTestError.create

      subject(:error) { AndAnotherTestError.new }

      it "inherits the ID generator" do
        expect(error.id).to eq(42)
      end

      it "inherits the pretty name" do
        expect(error.class.pretty_name).to eq('So Pretty')
      end
    end
  end

  def get_error
    f1
  rescue => error
    error
  end

  def f1
    f2
  rescue
    raise FirstTestError.new(["I love {{cake}}.", "So does the president, {{president}}."], cake: 'cheesecake', president: 'Donald')
  end

  def f2
    f3
  rescue
    raise ArgumentError, "an argument error"
  end

  def f3
    f4
  rescue
    raise StandardError, "a standard error"
  end

  def f4
    raise SecondTestError.new(["The world loves {{cake}}.", "So does the queen, {{queen}}."], cake: 'nata', queen: 'Isabel')
  end

  describe ".children" do
    subject(:error) { get_error }

    it "returns an array with the chain of exceptions that caused the error" do
      expect(error.children.size).to eq(3)
      expect(error.children.first).to be_instance_of(ArgumentError)
      expect(error.children.second).to be_instance_of(StandardError)
      expect(error.children.third).to be_instance_of(SecondTestError)
    end
  end

  describe ".root_cause" do
    subject(:error) { get_error }

    specify do
      expect(error.root_cause).to be_instance_of(SecondTestError)
    end
  end

  describe "#details" do
    subject(:error) { get_error }

    it "returns an array with the details of the error, rendered with Liquid" do
      expect(error.details).to eq(['I love cheesecake.', 'So does the president, Donald.'])
    end
  end

  describe "#to_h" do
    subject(:error) { get_error }

    specify do
      expected_hash = {
        id: kind_of(String),
        name: 'FirstTestError',
        pretty_name: 'First Test',
        details: ['I love cheesecake.', 'So does the president, Donald.'],
        context: { "cake" => "cheesecake", "president" => "Donald" }
      }
      expect(subject.to_h).to match(expected_hash)
    end

    context "when asked to include children" do
      specify do
        expected_hash = {
          id: kind_of(String),
          name: 'FirstTestError',
          pretty_name: 'First Test',
          details: ['I love cheesecake.', 'So does the president, Donald.'],
          context: { "cake" => "cheesecake", "president" => "Donald" },
          child: {
            name: 'ArgumentError',
            details: ['an argument error'],
            child: {
              name: 'StandardError',
              details: ['a standard error'],
              child: {
                id: kind_of(String),
                name: 'SecondTestError',
                pretty_name: 'Second Test',
                details: ['The world loves nata.', 'So does the queen, Isabel.'],
                context: { "cake" => "nata", "queen" => "Isabel" }
              }
            }
          }
        }
        expect(subject.to_h(include_children: true)).to match(expected_hash)
      end
    end
  end

end

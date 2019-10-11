RSpec.describe BetterError do

  class ImAnError < BetterError; end

  it "is an abstract call" do
    expect { BetterError.new }.to raise_error(StandardError)
    expect(ImAnError.new).to be_truthy
  end

  describe "defaults" do
    subject(:error) { ImAnError.new }

    specify "#id returns an UUID V4" do
      expect(error.id).to match(/^[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i)
    end

    specify ".pretty_error" do
      expect(error.class.pretty_name).to eq('Im An')
    end
  end

  describe ".create" do
    YetAnotherError = ImAnError.create(pretty_name: 'So Pretty', id_generator: -> { 42 })

    subject(:error) { YetAnotherError.new }

    it "creates a subclass" do
      expect(error).to be_a(ImAnError)
    end

    specify "#id" do
      expect(error.id).to eq(42)
    end

    specify ".id" do
      expect(error.class.pretty_name).to eq('So Pretty')
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
    raise ImAnError.new(["I love {{cake}}.", "So does the president, {{president}}."], cake: 'cheesecake', president: 'Donald')
  end

  def f2
    f3
  rescue
    raise ArgumentError, "an argument error"
  end

  def f3
    raise StandardError, "a standard error"
  end

  describe ".children" do
    subject(:error) { get_error }

    it "returns an array with the chain of exceptions that caused the error" do
      expect(error.children.size).to eq(2)
      expect(error.children.first).to be_instance_of(ArgumentError)
      expect(error.children.last).to be_instance_of(StandardError)
    end
  end

  describe ".root_cause" do
    subject(:error) { get_error }

    specify do
      expect(error.root_cause).to be_instance_of(StandardError)
    end
  end

  describe "#details" do
    subject(:error) { get_error }

    it "returns an array with the details of the error, rendered with Liquid" do
      expect(error.details).to eq(['I love cheesecake.', 'So does the president, Donald.'])
    end

    context "when asked to include children" do
      specify do
        expect(error.details(include_children: true)).to eq(['I love cheesecake.', 'So does the president, Donald.', 'an argument error', 'a standard error'])
      end
    end
  end

end

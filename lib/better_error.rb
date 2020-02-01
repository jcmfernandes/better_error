# frozen_string_literal: true

require 'securerandom'
require 'liquid'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/array/wrap'

require 'better_error/version'

class ::BetterError < ::StandardError
  attr_accessor :id
  attr_reader   :context
  attr_writer   :caused_by

  def self.create(pretty_name: nil, superclass: self, id_generator: nil)
    raise ::ArgumentError, "#{super_class} isn't a subclass of #{name}" unless superclass == self || superclass.ancestors.include?(self)

    klass = ::Class.new(superclass)
    klass.pretty_name = pretty_name unless pretty_name.nil?
    klass.id_generator = id_generator unless id_generator.nil?

    klass
  end

  def self.id_generator
    SecureRandom.uuid.freeze
  end

  def self.id_generator=(generator)
    define_singleton_method(:id_generator, &generator)
  end

  def self.pretty_name
    words = name.demodulize.scan(/[A-Z][a-z]+/.freeze)
    return name if words.pop != 'Error' || words.empty?

    words.join(' ').freeze
  end

  def self.pretty_name=(pretty_name)
    block = pretty_name.is_a?(::Proc) ? pretty_name : proc { pretty_name }
    define_singleton_method(:pretty_name, &block)
  end

  def initialize(detail = nil,
                 id: self.class.id_generator,
                 caused_by: nil,
                 **context)
    raise "abstract class" if self.class == ::BetterError

    @id = id
    @details = ::Array.wrap(detail)
    @context = ::ActiveSupport::HashWithIndifferentAccess.new
    @caused_by = caused_by

    self << context
  end

  def <<(data)
    case data
    when ::Hash
      @context.merge!(data)
    when ::Array
      @details.concat(data)
    else
      @details << data
    end

    self
  end

  def children
    return @children if defined?(@children)

    result = []
    error = cause
    return @children = result if error.nil?

    loop do
      result << error
      return @children = result if error.cause.nil?

      error = error.cause
    end
  end

  alias_method :causes, :children

  def cause
    @caused_by || super
  end

  alias_method :caused_by, :cause

  def root_cause
    return @root_cause if defined?(@root_cause) || cause.nil?

    result = nil
    error = cause
    loop do
      result = error
      return @root_cause = result if error.cause.nil?

      error = error.cause
    end
  end

  def details
    @details.map do |template|
      ::Liquid::Template.parse(template).render(context)
    end
  end

  def detail(join_with: "\n")
    details.join(join_with)
  end

  def to_s
    string = detail
    string.empty? ? super : string
  end

  def to_h(include_children: false, include_backtrace: false)
    return as_hash(include_backtrace: include_backtrace) unless include_children

    child = nil
    children.reverse_each do |error|
      hash =
        if error.is_a?(::BetterError)
          error.as_hash(include_backtrace: include_backtrace)
        else
          hash_from_worst_error(error, include_backtrace: include_backtrace)
        end
      hash[:child] = child unless child.nil?

      child = hash
    end

    result = self.as_hash(include_backtrace: include_backtrace)
    result[:child] = child unless child.nil?
    result
  end

  def inspect
    "#<#{self.class.name}:0x#{object_id.to_s(16)} id: #{id}, details: #{details}, context: #{context}, cause: #{cause.inspect}>"
  end

  protected

  def as_hash(include_backtrace:)
    {
      id: id,
      name: self.class.name,
      pretty_name: self.class.pretty_name,
      details: details,
      context: context,
    }.tap do |hash|
      hash[:backtrace] = backtrace if include_backtrace
    end
  end

  private

  def hash_from_worst_error(error, include_backtrace:)
    {
      name: error.class.name,
      details: [error.message]
    }.tap do |hash|
      hash[:backtrace] = error.backtrace if include_backtrace
    end
  end
end

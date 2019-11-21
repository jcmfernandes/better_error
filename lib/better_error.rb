# frozen_string_literal: true

require 'securerandom'
require 'liquid'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/array/wrap'

class ::BetterError < ::StandardError
  attr_accessor :id
  attr_reader   :context
  attr_writer   :caused_by

  def self.create(pretty_name: nil, superclass: self, id_generator: nil)
    raise ::ArgumentError, "#{super_class} isn't a subclass of #{name}" unless superclass == self || superclass.ancestors.include?(self)

    klass = ::Class.new(superclass)

    case pretty_name
    when nil
      nil
    when ::Proc
      klass.define_singleton_method(:pretty_name, &pretty_name)
    else
      klass.define_singleton_method(:pretty_name) { pretty_name }
    end

    klass.define_singleton_method(:id_generator, &id_generator) unless id_generator.nil?

    klass
  end

  def self.id_generator
    SecureRandom.uuid.freeze
  end

  def self.pretty_name
    words = name.demodulize.scan(/[A-Z][a-z]+/.freeze)
    return name if words.pop != 'Error' || words.empty?

    words.join(' ').freeze
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
      context.merge!(data)
    when ::Array
      @details.concat(data)
    else
      @details << data
    end

    self
  end

  def children
    result = []
    error = cause
    return result if error.nil?

    loop do
      result << error
      return result if error.cause.nil?

      error = error.cause
    end
  end

  alias_method :causes, :children

  def cause
    @caused_by || super
  end

  alias_method :caused_by, :cause

  def root_cause
    children.last
  end

  def details(include_children: false)
    details_from_context(include_children: include_children, context: context)
  end

  def detail(include_children: false)
    details(include_children: include_children).join("\n")
  end

  def to_s
    detail.then { |string| string.empty? ? super : string }
  end

  def to_h(include_children: false, include_backtrace: false)
    return as_hash(include_backtrace: include_backtrace, include_children: true) unless include_children

    tree = [self].concat(children).reverse!
    tree.map!.with_index do |error, i|
      hash =
        case error
        when ::BetterError
          error.as_hash(include_backtrace: include_backtrace, include_children: false)
        else
          hash_from_worst_error(error, include_backtrace: include_backtrace)
        end
      hash.merge!(child: i > 0 ? tree[i - 1] : nil)
    end
    tree.last
  end

  def inspect
    "#<#{self.class.name}:0x#{object_id.to_s(16)} id: #{id}, details: #{details}, context: #{context}, cause: #{cause.inspect}>"
  end

  protected

  def as_hash(include_backtrace:, include_children:)
    {
      id: id,
      name: self.class.name,
      pretty_name: self.class.pretty_name,
      details: details(include_children: include_children),
      context: context,
    }.tap do |hash|
      hash[:backtrace] = backtrace if include_backtrace
    end
  end

  def details_from_context(include_children:, context:)
    result = @details.map do |detail|
      ::Liquid::Template.parse(detail).render(context)
    end

    if include_children
      children_details = children.flat_map do |error|
        case error
        when ::BetterError
          error.details_from_context(include_children: false, context: context)
        else
          error.message
        end
      end
      result.concat(children_details)
    end

    result
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

# Copyright 2017 OpenCensus Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module OpenCensus
  module Common
    ##
    # OpenCensus configuration class.
    #
    # Configuration mechanism for OpenCensus libraries. A Config object contains
    # a list of predefined keys, some of which are values and others of which
    # are subconfigurations, i.e. categories. Option values are generally
    # validated to ensure they are the correct type.
    #
    # You generally access fields and subconfigs by calling accessor methods.
    # Only explicitly defined fields have these accessor methods defined.
    # Methods meant for "administration" such as adding options, are always
    # named with a trailing "!" or "?" so they don't pollute the method
    # namespace.
    #
    # Example:
    #
    #     config = OpenCensus::Common::Config.new do |c|
    #       c.add_option! :opt1, 10
    #       c.add_option! :opt2, :one, enum: [:one, :two, :three]
    #       c.add_option! :opt3, "hi", match: [String, Symbol]
    #       c.add_option! :opt4, "hi", match: /^[a-z]+$/, allow_nil: true
    #       c.add_config! :sub do |c2|
    #         c2.add_option! :opt5, false
    #       end
    #     end
    #
    #     config.opt1             #=> 10
    #     config.opt1 = 20        #=> 20
    #     config.opt1             #=> 20
    #     config.opt1 = "hi"      #=> exception (only Integer allowed)
    #     config.opt1 = nil       #=> exception (nil not allowed)
    #
    #     config.opt2             #=> :one
    #     config.opt2 = :two      #=> :two
    #     config.opt2             #=> :two
    #     config.opt2 = :four     #=> exception (not in allowed enum)
    #     config.opt2 = nil       #=> exception (nil not allowed)
    #
    #     config.opt3             #=> "hi"
    #     config.opt3 = "hiho"    #=> "hiho"
    #     config.opt3             #=> "hiho"
    #     config.opt3 = "HI"      #=> exception (regexp check failed)
    #     config.opt3 = nil       #=> exception (nil not allowed)
    #
    #     config.opt4             #=> "yo"
    #     config.opt4 = :yo       #=> :yo  (Strings and Symbols allowed)
    #     config.opt4             #=> :yo
    #     config.opt4 = 3.14      #=> exception (not in allowed types)
    #     config.opt4 = nil       #=> nil  (nil explicitly allowed)
    #
    #     config.sub              #=> <OpenCensus::Common::Config>
    #
    #     config.sub.opt5         #=> false
    #     config.sub.opt5 = true  #=> true  (true and false allowed)
    #     config.sub.opt5         #=> true
    #     config.sub.opt5 = nil   #=> exception (nil not allowed)
    #
    #     config.opt9             #=> exception (unknown key)
    #     config.sub.opt9         #=> exception (unknown key)
    #
    class Config
      ##
      # Constructs a Configuration object. If a block is given, yields `self`
      # to the block, which makes it convenient to initialize the structure by
      # making calls to {Config#add_option!}, {Config#add_config!}, and
      # {Config#add_alias!}.
      #
      def initialize
        @fields = {}
        yield self if block_given?
      end

      ##
      # Add an option field to this configuration.
      #
      # You must provide a key, which becomes the field name in this config.
      # Field names may comprise only letters, numerals, and underscores, and
      # must begin with a letter. This will create accessor methods for the
      # new configuration key.
      #
      # You may pass an initial value (which defaults to nil if not provided).
      #
      # You may also specify how values are validated. Validation is defined
      # as follows:
      #
      # *   If you provide a block or a `:validator` option, it is used as the
      #     validator. A proposed value is passed to the proc, and it should
      #     return true or false to indicate whether the value is acceptable.
      # *   If you provide a `:match` option, it is compared to the proposed
      #     value using the `===` operator. You may, for example, provide a
      #     class, a regular expression, or a range. If you pass an array,
      #     the value is accepted if _any_ of the elements match.
      # *   If you provide an `:enum` option, it should be an `Enumerable`.
      #     A proposed value is accepted if it is included.
      # *   Otherwise if you do not provide any of the above options, then a
      #     default validation strategy is inferred from the initial value:
      #     *   If the initial is `true` or `false`, then either boolean value
      #         is considered valid. This is the same as `enum: [true, false]`.
      #     *   If the initial is `nil`, then any object is considered valid.
      #     *   Otherwise, any object of the same class as the initial value is
      #         considered valid. This is effectively the same as
      #         `match: initial.class`.
      # *   You may also provide the `:allow_nil` option, which, if set to
      #     true, alters any of the above validators to allow `nil` values.
      #     If the initial value is `nil` but a specific validator is provided
      #     via `:match` or `:enum`, then `:allow_nil` defaults to true,
      #     otherwise it defaults to false.
      #
      # In many cases, you may find that the default validation behavior
      # (interpreted from the initial value) is sufficient. If you want to
      # accept any value, use `match: Object`.
      #
      # @param [String, Symbol] key The name of the option
      # @param [Object] initial Initial value (defaults to nil)
      # @param [Hash] opts Validation options
      #
      # @return [Config] self for chaining
      #
      def add_option! key, initial = nil, opts = {}, &block
        key = validate_new_key! key
        opts[:validator] = block if block
        validator = resolve_validator! initial, opts
        validate_value! key, validator, initial
        @fields[key] = Option.new initial, initial, validator
        define_getter_method! key
        define_setter_method! key
        self
      end

      ##
      # Add a subconfiguration field to this configuration.
      #
      # You must provide a key, which becomes the method name that you use to
      # navigate to the subconfig. Names may comprise only letters, numerals,
      # and underscores, and must begin with a letter.
      #
      # If you provide a block, the subconfig object is passed to the block,
      # so you can easily add fields.
      #
      # @param [String, Symbol] key The name of the subconfig
      #
      # @return [Config] self for chaining
      #
      def add_config! key, &block
        key = validate_new_key! key
        @fields[key] = Config.new(&block)
        define_getter_method! key
        self
      end

      ##
      # Add a field to this configuration that is an alias of some other
      # object, which may be another field or another configuration. This will
      # effectively become an alternate "path" to that same object.
      #
      # The following cases are supported:
      #
      # * Alias another configuration at this key by providing a `config`
      #   parameter but not a `key`. The given configuration is effectively
      #   "attached" as a subconfiguration; both the original configuration
      #   path, and this new key, point to the same configuration object and
      #   share configuration data.
      # * Alias another field of this current configuration by providing a
      #   `key` parameter but not a `config`. The new key simply refers to the
      #   same object (which may be an option or a subconfig) as the original
      #   key, and shares the same data.
      # * Alias another field or another configuration, by providing both a
      #   `config` parameter and a `key` parameter.
      #
      # @param [String, Symbol] new_key The key to alias.
      # @param [Config, nil] config The original configuration.
      # @param [String, Symbol, nil] key The original field name.
      #
      # @return [Config] self for chaining
      #
      def add_alias! new_key, config: nil, key: nil
        new_key = validate_new_key! new_key
        if config.nil? && key.nil?
          raise ArgumentError, "You must provide a config and/or key."
        end
        field =
          if key.nil?
            config
          else
            (config || self).raw_field! key
          end
        @fields[new_key] = field
        define_getter_method! new_key
        define_setter_method! new_key if field.is_a? Option
        self
      end

      ##
      # Restore the original default value of the given key.
      # If the key refers to a subconfiguration, restore its contents,
      # recursively. If the key is omitted, restore the original defaults for
      # all keys, including subconfigurations recursively.
      #
      # @param [Symbol, nil] key The key to reset. If omitted or `nil`,
      #     recursively reset all fields and subconfigs.
      #
      def reset! key = nil
        if key.nil?
          @fields.each_key { |k| reset! k }
        else
          key = key.to_sym
          unless @fields.key? key
            raise ArgumentError, "Key #{key.inspect} does not exist"
          end
          field = @fields[key]
          if field.is_a? Config
            field.reset!
          else
            field.value = field.default
          end
        end
        self
      end

      ##
      # Remove the given key from the configuration.
      # If the key is omitted, deletes all keys.
      #
      # Note the actual object being referenced is not touched. So if a deleted
      # option is an alias of some other option, the other option will remain
      # and retain the setting. Similarly, if a subconfig is referenced
      # elsewhere, it will remain accessible from that other location.
      #
      # @param [Symbol, nil] key The key to delete. If omitted or `nil`,
      #     delete all fields and subconfigs.
      #
      def delete! key = nil
        if key.nil?
          @fields.clear
        else
          key = key.to_sym
          unless @fields.key? key
            raise ArgumentError, "Key #{key.inspect} does not exist"
          end
          field = @fields.delete key
          singleton_class.send :remove_method, :"#{key}"
          singleton_class.send :remove_method, :"#{key}=" if field.is_a? Option
        end
        self
      end

      ##
      # Assign an option with the given name to the given value.
      #
      # @param [Symbol, String] key The option name
      # @param [Object] value The new option value
      #
      def []= key, value
        key = key.to_sym
        unless @fields.key? key
          raise ArgumentError, "Key #{key.inspect} does not exist"
        end
        field = @fields[key]
        if field.is_a? Config
          raise ArgumentError, "Key #{key.inspect} is a subconfig"
        end
        validate_value! key, field.validator, value
        field.value = value
      end

      ##
      # Get the option or subconfig with the given name.
      #
      # @param [Symbol, String] key The option or subconfig name
      # @return [Object] The option value or subconfig object
      #
      def [] key
        key = key.to_sym
        unless @fields.key? key
          raise ArgumentError, "Key #{key.inspect} does not exist"
        end
        field = @fields[key]
        if field.is_a? Config
          field
        else
          field.value
        end
      end

      ##
      # Check if this Config object has an option of the given name.
      #
      # @param [Symbol] key The key to check for.
      # @return [boolean] true if the inquired key is a valid option for this
      #   Config object. False otherwise.
      #
      def option? key
        @fields[key.to_sym].is_a? Option
      end

      ##
      # Check if this Config object has a subconfig of the given name.
      #
      # @param [Symbol] key The key to check for.
      # @return [boolean] true if the inquired key is a valid subconfig of this
      #   Config object. False otherwise.
      #
      def subconfig? key
        @fields[key.to_sym].is_a? Config
      end

      ##
      # Check if this Config object has a key of the given name, regardless of
      # whether it is an option or a subconfig.
      #
      # @param [Symbol] key The key to check for.
      # @return [boolean] true if the key exists.
      #
      def key? key
        @fields.key? key.to_sym
      end

      ##
      # Return a list of valid option names.
      #
      # @return [Array<Symbol>] a list of option names as symbols.
      #
      def options!
        @fields.keys.find_all { |key| @fields[key].is_a? Option }
      end

      ##
      # Return a list of valid subconfig names.
      #
      # @return [Array<Symbol>] a list of subconfig names as symbols.
      #
      def subconfigs!
        @fields.keys.find_all { |key| @fields[key].is_a? Config }
      end

      ##
      # Return a list of valid keys, including both options and subconfigs.
      #
      # @return [Array<Symbol>] a list of keys as symbols.
      #
      def keys!
        @fields.keys
      end

      ##
      # Returns a string representation of this configuration state.
      #
      # @return [String]
      #
      def to_s!
        elems = @fields.map do |k, v|
          vstr =
            if v.is_a? Config
              v.to_s!
            else
              v.value.inspect
            end
          " #{k}=#{vstr}"
        end
        "<Config#{elems.join}>"
      end

      ##
      # Returns a nested hash representation of this configuration state,
      # including subconfigurations.
      #
      # @return [Hash]
      #
      def to_h!
        result = {}
        @fields.each do |k, v|
          result[k] = v.is_a?(Config) ? v.to_h! : v.value
        end
        result
      end

      ##
      # Override the default to_s implementation.
      #
      # @private
      #
      def to_s
        to_s!
      end

      ##
      # Override the default inspect implementation.
      #
      # @private
      #
      def inspect
        to_s!
      end

      ##
      # Override the default to_h implementation.
      #
      # @private
      #
      def to_h
        to_h!
      end

      protected

      ##
      # Get the raw value of the field hash for the given key.
      #
      # @private
      #
      def raw_field! key
        key = key.to_sym
        unless @fields.key? key
          raise ArgumentError, "Key #{key.inspect} does not exist"
        end
        @fields[key]
      end

      private

      ##
      # Internal data structure to hold configuration options
      #
      # @private
      #
      Option = Struct.new :value, :default, :validator

      ##
      # A validator that allows all values
      #
      # @private
      #
      OPEN_VALIDATOR = ::Proc.new { true }

      def validate_new_key! key
        key_str = key.to_s
        unless key_str =~ /^\w+$/
          raise ArgumentError, "Illegal key: #{key_str.inspect}"
        end
        key = key.to_sym
        if @fields.key? key
          raise ArgumentError, "Key #{key.inspect} already exists"
        end
        key
      end

      def resolve_validator! initial, opts
        allow_nil = initial.nil? || opts[:allow_nil]
        if opts.key? :validator
          build_proc_validator! opts[:validator], allow_nil
        elsif opts.key? :match
          build_match_validator! opts[:match], allow_nil
        elsif opts.key? :enum
          build_enum_validator! opts[:enum], allow_nil
        elsif [true, false].include? initial
          build_enum_validator! [true, false], allow_nil
        elsif initial.nil?
          OPEN_VALIDATOR
        else
          build_match_validator! initial.class, allow_nil
        end
      end

      def build_match_validator! matches, allow_nil
        matches = Array(matches)
        matches += [nil] if allow_nil && !matches.include?(nil)
        ->(val) { matches.any? { |m| m === val } }
      end

      def build_enum_validator! allowed, allow_nil
        allowed = Array(allowed)
        allowed += [nil] if allow_nil && !allowed.include?(nil)
        ->(val) { allowed.include? val }
      end

      def build_proc_validator! proc, allow_nil
        ->(val) { proc.call(val) || allow_nil && val.nil? }
      end

      def validate_value! key, validator, value
        unless validator.call value
          raise ArgumentError,
                "Invalid value #{value.inspect} for key #{key.inspect}"
        end
      end

      def define_getter_method! key
        define_singleton_method key do
          field = @fields[key]
          if field.is_a? Config
            field
          else
            field.value
          end
        end
      end

      def define_setter_method! key
        define_singleton_method :"#{key}=" do |value|
          field = @fields[key]
          validate_value! key, field.validator, value
          field.value = value
        end
      end
    end
  end
end

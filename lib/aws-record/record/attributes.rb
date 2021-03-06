# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not
# use this file except in compliance with the License. A copy of the License is
# located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions
# and limitations under the License.

module Aws
  module Record
    module Attributes

      def self.included(sub_class)
        sub_class.extend(ClassMethods)
        sub_class.instance_variable_set("@keys", {})
        sub_class.instance_variable_set("@attributes", {})
        sub_class.instance_variable_set("@storage_attributes", {})
      end

      # @example Usage Example
      #   class MyModel
      #     include Aws::Record
      #     integer_attr :id,   hash_key: true
      #     string_attr  :name, range_key: true
      #     string_attr  :body
      #   end
      #
      #   item = MyModel.new(id: 1, name: "Quick Create")
      #
      # Base initialization method for a new item. Optionally, allows you to
      # provide initial attribute values for the model. You do not need to
      # provide all, or even any, attributes at item creation time.
      #
      # @param [Hash] attr_values Attribute symbol/value pairs for any initial
      #  attribute values you wish to set.
      # @return [Aws::Record] An item instance for your model.
      def initialize(attr_values = {})
        @data = {}
        attr_values.each do |attr_name, attr_value|
          send("#{attr_name}=", attr_value)
        end
      end

      # Returns a hash representation of the attribute data.
      #
      # @return [Hash] Map of attribute names to raw values.
      def to_h
        @data.dup
      end

      private

      # @private
      def read_attribute(name, attribute)
        raw = @data[name]
        attribute.type_cast(raw)
      end

      # @private
      def write_attribute(name, attribute, value)
        @data[name] = value
      end
        

      module ClassMethods

        # Define an attribute for your model, providing your own attribute type.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Marshaler] marshaler The marshaler for this attribute. So long
        #   as you provide a marshaler which implements +#type_cast+ and
        #   +#serialize+ that consume raw values as expected, you can bring your
        #   own marshaler type. Convenience methods will provide this for you.
        # @param [Hash] opts
        # @option opts [String] :database_attribute_name Optional attribute
        #   used to specify a different name for database persistence than the
        #   `name` parameter. Must be unique (you can't have overlap between
        #   database attribute names and the names of other attributes).
        # @option opts [String] :dynamodb_type Generally used for keys and
        #   index attributes, one of "S", "N", "B", "BOOL", "SS", "NS", "BS",
        #   "M", "L". Optional if this attribute will never be used for a key or
        #   secondary index, but most convenience methods for setting attributes
        #   will provide this.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is false.
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        def attr(name, marshaler, opts = {})
          validate_attr_name(name)

          opts = opts.merge(marshaler: marshaler)
          attribute = Attribute.new(name, opts)

          storage_name = attribute.database_name

          check_for_naming_collisions(name, storage_name)
          check_if_reserved(name)

          @attributes[name] = attribute
          @storage_attributes[storage_name] = name

          define_attr_methods(name, attribute)
          key_attributes(name, opts)
        end

        # Define a string-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is false.
        def string_attr(name, opts = {})
          opts[:dynamodb_type] = "S"
          attr(name, Attributes::StringMarshaler, opts)
        end

        # Define a boolean-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is false.
        def boolean_attr(name, opts = {})
          opts[:dynamodb_type] = "BOOL"
          attr(name, Attributes::BooleanMarshaler, opts)
        end

        # Define a integer-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is false.
        def integer_attr(name, opts = {})
          opts[:dynamodb_type] = "N"
          attr(name, Attributes::IntegerMarshaler, opts)
        end

        # Define a float-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is false.
        def float_attr(name, opts = {})
          opts[:dynamodb_type] = "N"
          attr(name, Attributes::FloatMarshaler, opts)
        end

        # Define a date-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is false.
        def date_attr(name, opts = {})
          opts[:dynamodb_type] = "S"
          attr(name, Attributes::DateMarshaler, opts)
        end

        # Define a datetime-type attribute for your model.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is false.
        def datetime_attr(name, opts = {})
          opts[:dynamodb_type] = "S"
          attr(name, Attributes::DateTimeMarshaler, opts)
        end

        # Define a list-type attribute for your model.
        #
        # Lists do not have to be homogeneous, but they do have to be types that
        # the AWS SDK for Ruby V2's DynamoDB client knows how to marshal and
        # unmarshal. Those types are:
        #
        # * Hash
        # * Array
        # * String
        # * Numeric
        # * Boolean
        # * IO
        # * Set
        # * nil
        #
        # Also note that, since lists are heterogeneous, you may lose some
        # precision when marshaling and unmarshaling. For example, symbols will
        # be stringified, but there is no way to return those strings to symbols
        # when the object is read back from DynamoDB.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :nil_as_empty_list Set to true if this
        #   attribute should interpret nil values as an empty list. If false,
        #   nil values will remain nil.
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is true.
        def list_attr(name, opts = {})
          opts[:dynamodb_type] = "L"
          opts[:mutation_tracking] = true if opts[:mutation_tracking].nil?
          attr(name, Attributes::ListMarshaler, opts)
        end

        # Define a map-type attribute for your model.
        #
        # Maps do not have to be homogeneous, but they do have to use types that
        # the AWS SDK for Ruby V2's DynamoDB client knows how to marshal and
        # unmarshal. Those types are:
        #
        # * Hash
        # * Array
        # * String
        # * Numeric
        # * Boolean
        # * IO
        # * Set
        # * nil
        #
        # Also note that, since maps are heterogeneous, you may lose some
        # precision when marshaling and unmarshaling. For example, symbols will
        # be stringified, but there is no way to return those strings to symbols
        # when the object is read back from DynamoDB.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :nil_as_empty_map Set to true if this
        #   attribute should interpret nil values as an empty hash. If false,
        #   nil values will remain nil.
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is true.
        def map_attr(name, opts = {})
          opts[:dynamodb_type] = "M"
          opts[:mutation_tracking] = true if opts[:mutation_tracking].nil?
          attr(name, Attributes::MapMarshaler, opts)
        end

        # Define a string set attribute for your model.
        #
        # String sets are homogeneous sets, containing only strings. Note that
        # empty sets cannot be persisted to DynamoDB. Empty sets are valid for
        # aws-record items, but they will not be persisted as sets. nil values
        # from your table, or a lack of value from your table, will be treated
        # as an empty set for item instances. At persistence time, the marshaler
        # will attempt to marshal any non-strings within the set to be String
        # objects.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is true.
        def string_set_attr(name, opts = {})
          opts[:dynamodb_type] = "SS"
          opts[:mutation_tracking] = true if opts[:mutation_tracking].nil?
          attr(name, Attributes::StringSetMarshaler, opts)
        end

        # Define a numeric set attribute for your model.
        #
        # Numeric sets are homogeneous sets, containing only numbers. Note that
        # empty sets cannot be persisted to DynamoDB. Empty sets are valid for
        # aws-record items, but they will not be persisted as sets. nil values
        # from your table, or a lack of value from your table, will be treated
        # as an empty set for item instances. At persistence time, the marshaler
        # will attempt to marshal any non-numerics within the set to be Numeric
        # objects.
        #
        # @param [Symbol] name Name of this attribute.  It should be a name that
        #   is safe to use as a method.
        # @param [Hash] opts
        # @option opts [Boolean] :hash_key Set to true if this attribute is
        #   the hash key for the table.
        # @option opts [Boolean] :range_key Set to true if this attribute is
        #   the range key for the table.
        # @option options [Boolean] :mutation_tracking Optional attribute used to
        #   indicate if mutations to values should be explicitly tracked when
        #   determining if a value is "dirty". Important for collection types
        #   which are often primarily modified by mutation of a single object
        #   reference. By default, is true.
        def numeric_set_attr(name, opts = {})
          opts[:dynamodb_type] = "NS"
          opts[:mutation_tracking] = true if opts[:mutation_tracking].nil?
          attr(name, Attributes::NumericSetMarshaler, opts)
        end

        # @return [Hash] hash of symbolized attribute names to attribute objects
        def attributes
          @attributes
        end

        # @return [Hash] hash of database names to attribute names
        def storage_attributes
          @storage_attributes
        end

        # @return [Aws::Record::Attribute,nil]
        def hash_key
          @attributes[@keys[:hash]]
        end

        # @return [Aws::Record::Attribute,nil]
        def range_key
          @attributes[@keys[:range]]
        end

        # @return [Hash] A mapping of the :hash and :range keys to the attribute
        #   name symbols associated with them.
        def keys
          @keys
        end

        # @param [Symbol] attr_sym The symbolized name of the attribute.
        # @return [Boolean] true if object mutations are tracked for dirty
        #   checking of that attribute, false if mutations are not tracked.
        def track_mutations?(attr_sym)
          mutation_tracking_enabled? && attributes[attr_sym].track_mutations?
        end

        private
        def define_attr_methods(name, attribute)
          define_method(name) do
            read_attribute(name, attribute)
          end

          define_method("#{name}=") do |value|
            write_attribute(name, attribute, value)
          end
        end

        def key_attributes(id, opts)
          if opts[:hash_key] == true && opts[:range_key] == true
            raise ArgumentError.new(
              "Cannot have the same attribute be a hash and range key."
            )
          elsif opts[:hash_key] == true
            define_key(id, :hash)
          elsif opts[:range_key] == true
            define_key(id, :range)
          end
        end

        def define_key(id, type)
          @keys[type] = id
        end

        def validate_attr_name(name)
          unless name.is_a?(Symbol)
            raise ArgumentError.new("Must use symbolized :name attribute.")
          end
          if @attributes[name]
            raise Errors::NameCollision.new(
              "Cannot overwrite existing attribute #{name}"
            )
          end
        end

        def check_if_reserved(name)
          if instance_methods.include?(name)
            raise Errors::ReservedName.new(
              "Cannot name an attribute #{name}, that would collide with an"\
                " existing instance method."
            )
          end
        end

        def check_for_naming_collisions(name, storage_name)
          if @attributes[storage_name.to_sym]
            raise Errors::NameCollision.new(
              "Custom storage name #{storage_name} already exists as an"\
                " attribute name in #{@attributes}"
            )
          elsif @storage_attributes[name.to_s]
            raise Errors::NameCollision.new(
              "Attribute name #{name} already exists as a custom storage"\
                " name in #{@storage_attributes}"
            )
          elsif @storage_attributes[storage_name]
            raise Errors::NameCollision.new(
              "Custom storage name #{storage_name} already in use in"\
                " #{@storage_attributes}"
            )
          end
        end
      end

    end
  end
end

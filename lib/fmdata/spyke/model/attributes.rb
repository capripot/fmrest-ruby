module FmData
  module Spyke
    module Model
      module Attributes
        extend ::ActiveSupport::Concern

        include ::ActiveModel::Dirty

        included do
          # Prevent the creation of plain (no prefix/suffix) attribute methods
          # when calling ActiveModels' define_attribute_method, otherwise it
          # will define an `attribute` method which overrides the one provided
          # by Spyke
          self.attribute_method_matchers.shift

          # Keep track of attribute mappings so we can get the FM field names
          # for changed attributes
          class_attribute :mapped_attributes, instance_writer: false, default: ::ActiveSupport::HashWithIndifferentAccess.new
        end

        class_methods do

          # Similar to Spyke::Base.attributes, but allows defining attribute
          # methods that map to FM attributes with different names.
          #
          # Example:
          #
          #   class Person < Spyke::Base
          #     include FmData::Spyke::Model
          #
          #     attributes first_name: "FstName", last_name: "LstName"
          #   end
          #
          #   p = Person.new
          #   p.first_name = "Jojo"
          #   p.attributes # => { "FstName" => "Jojo" }
          #
          def attributes(*attrs)
            if attrs.length == 1 && attrs.first.kind_of?(Hash)
              attrs.first.each { |from, to| _fmdata_define_attribute(from, to) }
            else
              attrs.each { |attr| _fmdata_define_attribute(attr, attr) }
            end
          end

          private

          def _fmdata_attribute_methods_container
            @fmdata_attribute_methods_container ||= Module.new.tap { |mod| include mod }
          end

          def _fmdata_define_attribute(from, to)
            mapped_attributes[from] = to

            _fmdata_attribute_methods_container.module_eval do
              define_method(from) do
                attribute(to)
              end

              define_method(:"#{from}=") do |value|
                send("#{from}_will_change!") unless value == send(from)
                set_attribute(to, value)
              end
            end

            # Define ActiveModel::Dirty's methods
            define_attribute_method(from)
          end
        end

        def initialize(*args)
          super.tap { clear_changes_information }
        end

        def save
          super.tap { |r| changes_applied if r }
        end

        def reload
          super.tap { |r| clear_changes_information if r }
        end

        # Override to_params to return FM Data API's expected JSON format, and
        # including only modified fields by default
        #
        def to_params(include_unchanged = false)
          params = {
            fieldData: include_unchanged ? params_not_embedded_in_url : changed_params_not_embedded_in_url
          }
          params[:modId] = mod_id if mod_id
          params
        end

        # ActiveModel::Dirty since version 5.2 assumes that if there's an
        # @attributes instance variable set we must be using ActiveRecord, so
        # we override the instance variable name used by Spyke to avoid issues.
        #
        # TODO: Submit a pull request to Spyke so this isn't needed
        #
        def attributes
          @_spyke_attributes
        end

        def attributes=(new_attributes)
          @_spyke_attributes ||= ::Spyke::Attributes.new(scope.params)
          use_setters(new_attributes) if new_attributes
        end

        private

        def changed_params_not_embedded_in_url
          params_not_embedded_in_url.slice(*mapped_changed)
        end

        def mapped_changed
          mapped_attributes.values_at(*changed)
        end
      end
    end
  end
end

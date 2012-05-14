module Sequel
  module Plugins
    module BulkAttributes
      def self.apply(model, opts={}, &block)
        model.plugin(:instance_hooks)
      end

      module ClassMethods
        private

        def def_bulk_setter(opts, &block)
          association_module_def(:"#{opts[:name]}=", opts, &block) unless opts[:read_only]
        end

        # Add a getter that checks the join table for matching records and
        # a setter that deletes from or inserts into the join table.
        def def_many_to_many(opts)
          super
          def_bulk_setter(opts) do |list|
            cur = send(opts[:name])
            instance_variable_set("@_#{opts[:name]}_add", list.reject{ |v| cur.detect{ |v1| v.pk == v1.pk } })
            instance_variable_set("@_#{opts[:name]}_remove", cur.reject{ |v| list.detect{ |v1| v.pk == v1.pk } })
            cur.replace(list)

            name = "#{opts[:name]}".singularize

            after_save_hook do
              instance_variable_get("@_#{opts[:name]}_remove").each do |record|
                send("remove_#{name}", record) if record && !record.empty?
              end

              instance_variable_get("@_#{opts[:name]}_add").each do |record|
                send("add_#{name}", record) if record && !record.empty?
              end
            end
          end
        end

        # Add a getter that checks the association dataset and a setter
        # that updates the associated table.
        def def_one_to_many(opts)
          super
          def_bulk_setter(opts) do |list|
            cur = send(opts[:name])
            instance_variable_set("@_#{opts[:name]}_add", list.reject{ |v| cur.detect{ |v1| v.pk == v1.pk } })
            instance_variable_set("@_#{opts[:name]}_remove", cur.reject{ |v| list.detect{ |v1| v.pk == v1.pk } })
            cur.replace(list)

            name = "#{opts[:name]}".singularize

            after_save_hook do
              instance_variable_get("@_#{opts[:name]}_remove").each do |record|
                send("remove_#{name}", record) if record && !record.empty?
              end

              instance_variable_get("@_#{opts[:name]}_add").each do |record|
                send("add_#{name}", record) if record && !record.empty?
              end
            end
          end
        end
      end

      module InstanceMethods
      end

      module DatasetMethods
      end
    end
  end
end

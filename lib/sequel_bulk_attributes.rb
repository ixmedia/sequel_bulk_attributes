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
            instance_variable_set("@_#{opts[:name]}_add", list.reject{ |v| cur.detect{ |v1| v == v1 } })
            instance_variable_set("@_#{opts[:name]}_remove", cur.reject{ |v| list.detect{ |v1| v == v1 } })
            cur.replace(list)

            after_save_hook do
              singular_name = opts[:name].to_s.singularize
              
              instance_variable_get("@_#{opts[:name]}_remove").each do |record|
                send("remove_#{singular_name}", record)
              end

              instance_variable_get("@_#{opts[:name]}_add").each do |record|
                send("add_#{singular_name}", record)
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

            after_save_hook do
              singular_name = opts[:name].to_s.singularize
              
              instance_variable_get("@_#{opts[:name]}_remove").each do |record|
                send("remove_#{singular_name}", record)
              end

              instance_variable_get("@_#{opts[:name]}_add").each do |record|
                send("add_#{singular_name}", record)
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

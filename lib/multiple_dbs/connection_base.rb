module MultipleDbs
  module MultiConnectable
    module ClassMethods

      def self.multiple_class(connectable_type)
        klass = Object.const_get("#{self.name}#{connectable_type.capitalize}")
        klass.branch_relations
        klass
      end

      def make_connectable_class( connection_sufix = "", &block)
        MultipleDbs::DBS.each do |db|
          ActiveRecord::Base.class_eval do
            Object.const_set("#{self.name}#{db.capitalize}", Class.new(self) do
              class_eval do
                before_validation :muliple_relations
                after_find :muliple_relations
                CONNECTABLE_TYPE = db.capitalize
                @connectable_relations = block_given? ? block : nil

                def self.muliple_relations
                  @connectable_relations.call( CONNECTABLE_TYPE ) if @connectable_relations
                end

                def self.connectable_type
                  CONNECTABLE_TYPE
                end

                private

                def connectable_type
                  CONNECTABLE_TYPE
                end

                def muliple_relations
                  self.class.muliple_relations
                end
              end
            end)
            eval("#{self.name}#{db.capitalize}")
            .establish_connection(
              Object.const_get("DBConnection#{db.capitalize}#{connection_sufix.to_s.capitalize}")
              .connection
            )
            eval("#{self.name}#{db.capitalize}").muliple_relations
          end
        end
      end
    end
  end
end

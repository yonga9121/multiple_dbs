Object.class_eval do
  def self.const_missing(c)
    matches = []
    db_matches = []
    MultipleDbs::DBS.each do |db|
      matches << c.to_s.scan(
        Regexp.new('(([A-Z]){1}([a-z]|[0-9])*)+' + db.to_s.capitalize + '$')
      )
      db_matches << db
      break if matches.any?
    end
    const_temp = Object.const_get(matches.first).multiple_class(db_matches.first) if matches.flatten!.any?
    return const_temp if matches.any? and const_temp.to_s.eql?(c.to_s)
    super
  end
end


module MultipleDbs
  module MultiConnectable
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods

      def multiple_class(connectable_type)
        klass = Object.const_get("#{self.name}#{connectable_type.capitalize}")
        klass.muliple_relations
        klass
      end

      def make_connectable_class(&block)
        MultipleDbs::DBS.each do |db|
          class_eval do
            Object.const_set("#{self.name}#{db.capitalize}", Class.new(self) do
              class_eval do
                before_validation :muliple_relations
                after_find :muliple_relations
                const_set("CONNECTABLE_TYPE",db.capitalize)

                @connectable_relations = block_given? ? block : nil

                def self.muliple_relations
                  @connectable_relations.call( const_get("CONNECTABLE_TYPE") ) if @connectable_relations
                end

                def self.connectable_type
                  const_get("CONNECTABLE_TYPE")
                end

                private

                def connectable_type
                  const_get("CONNECTABLE_TYPE")
                end

                def muliple_relations
                  self.class.muliple_relations
                end
              end
            end)
            Object.const_get("#{self.name}#{db.capitalize}").establish_connection(
              Object.const_get("MultipleDbs::DbConnection::#{db.capitalize}")
              .connection
            )
            Object.const_get("#{self.name}#{db.capitalize}").muliple_relations
          end
        end
      end
    end
  end
end

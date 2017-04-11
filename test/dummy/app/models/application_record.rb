class ApplicationRecord < ActiveRecord::Base
  include MultipleDbs::MultiConnectable
  self.abstract_class = true
end

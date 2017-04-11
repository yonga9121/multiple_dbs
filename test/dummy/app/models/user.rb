class User < ApplicationRecord

  make_connectable_class do |db|
    has_many :posts, class_name: "Post#{db}"
  end

end

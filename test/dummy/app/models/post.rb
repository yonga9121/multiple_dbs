class Post < ApplicationRecord

  make_connectable_class do |db|
    belongs_to :user, class_name: "User#{db}", foreign_key: "user_id"
  end
end

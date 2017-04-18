class Post < ApplicationRecord

  make_connectable_class do |db|
    belongs_to :user, foreign_key: "user_id",class_name: "User#{db}"
  end

end

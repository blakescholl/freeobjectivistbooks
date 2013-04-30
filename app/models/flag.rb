class Flag < ActiveRecord::Base
  self.inheritance_column = 'class'  # anything other than "type", to let us use "type" for something else

  belongs_to :user
  belongs_to :donation
end

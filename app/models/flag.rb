class Flag < ActiveRecord::Base
  self.inheritance_column = 'class'  # anything other than "type", to let us use "type" for something else

  belongs_to :user
  belongs_to :donation
  has_many :events

  Event.create_associations self

  validates_presence_of :type
  validates_presence_of :message, if: lambda {|f| f.type == 'shipping_info'}
  validates_presence_of :address, message: "We need your address to send you your book.", if: :fixed?
  validate :fix_message_or_detail_must_be_present, if: lambda {|f| f.fixed? && f.address.present?}

  def fix_message_or_detail_must_be_present
    if fix_type.blank? && fix_message.blank?
      errors[:fix_message] << "If you don't need to update your shipping info, please enter a message for your donor."
    end
  end

  delegate :request, :student, :donor, :fulfiller, :role_for, to: :donation, allow_nil: true
  delegate :address, :address=, to: :student, allow_nil: true
  delegate :name, :name=, to: :student, prefix: true

  def user_role
    role_for user
  end

  def fix(attributes)
    self.attributes = attributes
    self.fixed = true
    self.fix_type = student.update_detail
    donation.flag = nil
    fix_events.build
  end
end

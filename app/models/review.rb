# Represents a student's answer to "What did you think?" of a given book, after they have read it.
class Review < ActiveRecord::Base
  #--
  # Associations
  #++

  belongs_to :book
  belongs_to :user
  belongs_to :donation
  has_one :testimonial, as: :source

  #--
  # Validations
  #++

  validates_presence_of :user, :book, :text
  validates_inclusion_of :recommend, in: [true, false], message: 'Please choose "Yes" or "No".'

  #--
  # Scopes and finders
  #++

  default_scope order("created_at desc")

  scope :recommended, where(recommend: true)

  #--
  # Callbacks
  #++

  after_initialize :populate

  def populate
    unless id
      self.user ||= donation.student if donation
      self.book ||= donation.book if donation
    end
  end

  #--
  # Other methods
  #++

  # Creates a Testimonial based on this review.
  def to_testimonial
    Testimonial.new source: self, type: 'student', title: "On *#{book}*", text: text,
      attribution: "#{user.name}, studying #{user.studying.downcase} at #{user.school}"
  end
end

class Request < ActiveRecord::Base
  BOOKS = [
    "Atlas Shrugged",
    "The Fountainhead",
    "We the Living",
    "The Virtue of Selfishness",
    "Capitalism: The Unknown Ideal",
    "Objectivism: The Philosophy of Ayn Rand",
  ]

  BOOK_NOTES = {
    "Atlas Shrugged" => "(start here if you don't know what to choose!)",
    "Objectivism: The Philosophy of Ayn Rand" => "(by Leonard Peikoff)",
  }

  attr_accessor :other_book

  belongs_to :user

  validates_presence_of :book, message: "Please choose a book."
  validates_presence_of :reason, message: "This is required."
  validates_acceptance_of :pledge, message: "You must pledge to read this book.", allow_nil: false

  after_initialize do |request|
    request.book = "Atlas Shrugged" if request.book.blank?
  end

  before_validation do |request|
    request.book = request.other_book if request.book == "other"
  end
end
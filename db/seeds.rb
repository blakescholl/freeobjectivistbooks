# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

FEATURED_BOOKS = [
  {title: "Atlas Shrugged"},
  {title: "The Fountainhead"},
  {title: "We the Living"},
  {title: "The Virtue of Selfishness"},
  {title: "Capitalism: The Unknown Ideal"},
  {title: "Objectivism: The Philosophy of Ayn Rand", author: "Leonard Peikoff"},
]

rank = 0
FEATURED_BOOKS.each do |attributes|
  book = Book.find_or_create_by_title attributes[:title]
  book.attributes = attributes
  book.featured = true
  book.rank = rank
  book.save!
  rank += 1
end

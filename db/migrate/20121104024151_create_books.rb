class CreateBooks < ActiveRecord::Migration
  def up
    create_table :books do |t|
      t.string :title
      t.string :author
      t.boolean :featured
      t.integer :rank

      t.timestamps
    end

    change_table :requests do |t|
      t.rename :book, :book_deprecated
      t.references :book
    end

    change_table :reviews do |t|
      t.rename :book, :book_deprecated
      t.references :book
    end

    say_with_time "Backfilling books on requests" do
      Request.find_each do |request|
        request.book = Book.find_or_create_by_title request.book_deprecated
        request.save!
      end
    end

    say_with_time "Backfilling books on reviews" do
      Review.find_each do |review|
        review.book = Book.find_or_create_by_title review.book_deprecated
        review.save!
      end
    end
  end

  def down
    drop_table :books

    change_table :requests do |t|
      t.rename :book_deprecated, :book
      t.remove :book_id
    end

    change_table :reviews do |t|
      t.rename :book_deprecated, :book
      t.remove :book_id
    end
  end
end

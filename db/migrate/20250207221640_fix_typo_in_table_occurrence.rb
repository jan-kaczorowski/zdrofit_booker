class FixTypoInTableOccurrence < ActiveRecord::Migration[8.0]
  def change
    rename_column :zdrofit_class_bookings, :next_occurence, :next_occurrence
  end
end

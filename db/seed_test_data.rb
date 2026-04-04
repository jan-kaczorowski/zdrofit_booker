# Seed both users with test bookings
ZdrofitUser.all.each do |user|
  user.bookings.destroy_all
  puts "Cleared bookings for user #{user.id}: #{user.email}"

  bookings_data = [
    { class_name: "Crossfit Intro", trainer_name: "Anna Nowak", class_id: 101, club_id: 1, timetable_id: 501,
      occurrence: (DateTime.current + 3.days).change(hour: 18, min: 0) },
    { class_name: "Body Pump", trainer_name: "Marcin Kowalski", class_id: 102, club_id: 1, timetable_id: 502,
      occurrence: (DateTime.current + 4.days).change(hour: 9, min: 30) },
    { class_name: "Yoga Flow", trainer_name: "Katarzyna Wiśniewska", class_id: 103, club_id: 1, timetable_id: 503,
      occurrence: (DateTime.current + 5.days).change(hour: 17, min: 0) }
  ]

  bookings_data.each do |data|
    occ = data.delete(:occurrence)
    booking = user.bookings.create!(data)
    BookingEvent.insert!({ booking_id: booking.id, occurrence: occ, status: "pending", created_at: Time.current, updated_at: Time.current })
    puts "  Created: #{booking.class_name}"
  end

  # One with booked + pending
  booking = user.bookings.create!(class_name: "Pilates Core", trainer_name: "Ewa Mazur", class_id: 104, club_id: 1, timetable_id: 504)
  BookingEvent.insert!({ booking_id: booking.id, occurrence: (DateTime.current + 1.day).change(hour: 10, min: 0), status: "booked", created_at: Time.current, updated_at: Time.current })
  BookingEvent.insert!({ booking_id: booking.id, occurrence: (DateTime.current + 8.days).change(hour: 10, min: 0), status: "pending", created_at: Time.current, updated_at: Time.current })
  puts "  Created: Pilates Core (booked+pending)"

  # One failed
  booking = user.bookings.create!(class_name: "Boxing Circuit", trainer_name: "Tomasz Zieliński", class_id: 105, club_id: 1, timetable_id: 505)
  BookingEvent.insert!({ booking_id: booking.id, occurrence: (DateTime.current - 1.day).change(hour: 19, min: 0), status: "failed", debug_info: "Brak wolnych miejsc", created_at: Time.current, updated_at: Time.current })
  puts "  Created: Boxing Circuit (failed)"
end

puts "\nDone! Total bookings: #{Booking.count}, events: #{BookingEvent.count}"

module ZdrofitClient
  module ApiCalls
    class ListWeeklyClasses < ApiCall
      def call(club_id:, days_in_week: 1, date: nil, category_id: nil, time_table_id: nil, trainer_id: nil)
        Rails.logger.warn "ListWeeklyClasses.call: #{club_id}, #{date}"
        response = post(
          "/Classes/ClassCalendar/WeeklyClasses",
          body: {
            clubId: club_id,
            # date: date,
            categoryId: category_id,
            timeTableId: time_table_id,
            trainerId: trainer_id,
            daysInWeek: 7
          }
        )

        # Add filtering logic to the response
        filter_classes(response)
      end

      private

      def filter_classes(response)
        memo = []
        return response unless response["CalendarData"]

        response["CalendarData"].each do |zone|
          next unless zone["ClassesPerHour"]

          zone["ClassesPerHour"].each do |cph|
            next unless cph["ClassesPerDay"]

            cph["ClassesPerDay"].each do |classes_per_day|
              next unless classes_per_day.is_a?(Array)

              # Filter out classes that don't meet criteria
              classes_per_day.each do |el|
                next false unless el.is_a?(Hash)

                next unless el["Status"] == "Bookable" ||
                            (Time.parse(el["StartTime"]).future? && el.dig("BookingIndicator", "Available")&.to_i&.positive?)

                memo << el
              end
            end
          end
        end

        memo.sort_by { |el| DateTime.parse(el["StartTime"]) }
      end
    end
  end
end

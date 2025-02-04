module ZdrofitClient
  module ApiCalls
    class ListWeeklyClasses < ApiCall
      def call(club_id:, days_in_week: 1, date: nil, category_id: nil, time_table_id: nil, trainer_id: nil)
        response = post(
          "/Classes/ClassCalendar/WeeklyClasses",
          body: {
            clubId: club_id,
            date: date,
            categoryId: category_id,
            timeTableId: time_table_id,
            trainerId: trainer_id,
            daysInWeek: days_in_week
          }
        )

        # Add filtering logic to the response
        filter_classes(response)
      end

      private

      def filter_classes(response)
        return response unless response["CalendarData"]

        response["CalendarData"].each do |zone|
          next unless zone["ClassesPerHour"]

          zone["ClassesPerHour"].each do |cph|
            next unless cph["ClassesPerDay"]

            cph["ClassesPerDay"].each do |classes_per_day|
              next unless classes_per_day.is_a?(Array)

              # Filter out classes that don't meet criteria
              classes_per_day.select! do |el|
                next false unless el.is_a?(Hash)

                el["Status"] == "Bookable" ||
                  (el["Status"] == "Unavailable" && Time.parse(el["StartTime"]) > Time.current)
              end
            end
          end
        end

        response
      end
    end
  end
end

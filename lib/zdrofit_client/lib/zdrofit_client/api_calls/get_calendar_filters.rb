module ZdrofitClient
  module ApiCalls
    class GetCalendarFilters < ApiCall
      def call(club_id:)
        post(
          "/Classes/ClassCalendar/GetCalendarFilters",
          body: { clubId: club_id }
        )
      end
    end
  end
end 
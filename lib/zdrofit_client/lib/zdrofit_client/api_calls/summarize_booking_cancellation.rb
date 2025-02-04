module ZdrofitClient
  module ApiCalls
    class SummarizeBookingCancellation < ApiCall
      def call(timetable_event_id:)
        post(
          "/Classes/ClassCalendar/SummarizeBookingCancellation",
          body: { timeTableEventId: timetable_event_id }
        )
      end
    end
  end
end 
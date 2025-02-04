module ZdrofitClient
  module ApiCalls
    class CancelBooking < ApiCall
      def call(class_id:)
        post(
          "/Classes/ClassCalendar/CancelBooking",
          body: { classId: class_id }
        )
      end
    end
  end
end 
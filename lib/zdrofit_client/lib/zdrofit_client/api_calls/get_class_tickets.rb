module ZdrofitClient
  module ApiCalls
    class GetClassTickets < ApiCall
      def call(class_id:, user_id:)
        get(
          "/Classes/ClassCalendar/GetClassTickets",
          query: {
            classId: class_id,
            userId: user_id
          }
        )
      end
    end
  end
end 
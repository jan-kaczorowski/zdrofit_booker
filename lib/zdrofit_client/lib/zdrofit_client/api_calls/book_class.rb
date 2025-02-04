module ZdrofitClient
  module ApiCalls
    class BookClass < ApiCall
      def call(class_id:, club_id:)
        post(
          "/Classes/ClassCalendar/BookClass",
          body: {
            classId: class_id,
            clubId: club_id.to_s
          }
        )
      end
    end
  end
end

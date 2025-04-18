module ZdrofitClient
  module ApiCalls
    class GetClassDetails < ApiCall
      def call(class_id:)
        @client.get("/Classes/ClassCalendar/Details?classId=#{class_id}")
      end
    end
  end
end 
module ZdrofitClient
  module ApiCalls
    class GetMyCalendar < ApiCall
      def call
        get("/MyCalendar/MyCalendar/GetCalendar")
      end
    end
  end
end 
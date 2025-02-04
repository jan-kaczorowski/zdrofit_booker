module ZdrofitClient
  module ApiCalls
    class ListAvailableClubs < ApiCall
      def call
        get("/Clubs/GetAvailableClassesClubs")
      end
    end
  end
end 
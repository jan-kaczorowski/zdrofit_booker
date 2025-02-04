module ZdrofitClient
  module ApiCalls
    class GetIdentity < ApiCall
      def call
        post("/Auth/Login/Identity")
      end
    end
  end
end 
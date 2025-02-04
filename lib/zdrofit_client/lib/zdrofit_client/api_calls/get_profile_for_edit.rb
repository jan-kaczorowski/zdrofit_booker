module ZdrofitClient
  module ApiCalls
    class GetProfileForEdit < ApiCall
      def call(user_id:)
        post(
          "/Profile/Profile/GetProfileForEdit",
          body: { userId: user_id }
        )
      end
    end
  end
end 
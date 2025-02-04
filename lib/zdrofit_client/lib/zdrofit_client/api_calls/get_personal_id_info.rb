module ZdrofitClient
  module ApiCalls
    class GetPersonalIdInfo < ApiCall
      def call(country: "PL", personal_id:, user_type: "ClubMember")
        post(
          "/PersonalData/GetPersonalIdInfo",
          body: {
            country: country,
            personalId: personal_id,
            userType: user_type
          }
        )
      end
    end
  end
end 
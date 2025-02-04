class ZdrofitUser < ApplicationRecord
  encrypts :email
  encrypts :pass
end

class Api::V1::BloodPressuresController < Api::Current::BloodPressuresController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides
end

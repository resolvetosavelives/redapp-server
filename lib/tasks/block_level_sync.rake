require 'tasks/scripts/block_level_sync'

namespace :block_level_sync do
  desc "Enable block level sync for users"
  task enable: :environment do |_t, args|
    # bundle exec block_level_sync:enable[user_id_1,user_id_2,...]
    user_ids = args.extras
    BlockLevelSync.enable(user_ids)
  end

  desc "Disable block level sync for users"
  task disable: :environment do |_t, args|
    # bundle exec block_level_sync:disable[user_id_1,user_id_2,...]
    user_ids = args.extras
    BlockLevelSync.disable(user_ids)
  end

  desc "Bump block level sync for users"
  task :bump_percentage, [:percentage] => :environment do |_t, args|
    # bundle exec block_level_sync:bump_percentage[5]
    percentage = args.percentage
    BlockLevelSync.bump(percentage)
  end
end

class JsonLogger < Ougai::Logger
  include ActiveSupport::LoggerThreadSafeLevel
  include LoggerSilence

  def initialize(*args)
    super
    @before_log = lambda do |data|
      if RequestStore.store[:current_user_id]
        data[:current_user_id] = RequestStore.store[:current_user_id]
      end
    end
    after_initialize if respond_to? :after_initialize
  end

  def create_formatter
    if Rails.env.development? || Rails.env.test?
      Ougai::Formatters::Readable.new
    else
      Ougai::Formatters::Bunyan.new
    end
  end
end

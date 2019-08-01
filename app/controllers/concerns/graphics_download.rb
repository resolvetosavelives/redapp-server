module GraphicsDownload
  extend ActiveSupport::Concern

  included do
    private

    def render_as_png(view_name, filename, options = {})
      default_options = { width: 0,
                          height: 0,
                          enable_smart_width: true,
                          transparent: true,
                          quality: 100,
                          zoom: 1.0 }

      send_data(
        IMGKit.new(
          render_to_string(view_name, formats: [:html], layout: false),
          default_options.merge(options)).to_png,
        type: "image/png",
        filename: filename)
    end

    def graphics_filename(*args)
      "dashboard_snapshot_#{args.join('_')}.png"
    end
  end
end
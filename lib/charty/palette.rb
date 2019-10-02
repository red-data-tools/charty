require "numo/narray"

module Charty
  class Palette
    SEABORN_PALETTES = {
      "deep" => ["#4C72B0", "#DD8452", "#55A868", "#C44E52", "#8172B3",
                 "#937860", "#DA8BC3", "#8C8C8C", "#CCB974", "#64B5CD"].freeze,
      "deep6" => ["#4C72B0", "#55A868", "#C44E52",
                  "#8172B3", "#CCB974", "#64B5CD"].freeze,
      "muted" => ["#4878D0", "#EE854A", "#6ACC64", "#D65F5F", "#956CB4",
                  "#8C613C", "#DC7EC0", "#797979", "#D5BB67", "#82C6E2"].freeze,
      "muted6" => ["#4878D0", "#6ACC64", "#D65F5F",
                   "#956CB4", "#D5BB67", "#82C6E2"].freeze,
      "pastel" => ["#A1C9F4", "#FFB482", "#8DE5A1", "#FF9F9B", "#D0BBFF",
                   "#DEBB9B", "#FAB0E4", "#CFCFCF", "#FFFEA3", "#B9F2F0"].freeze,
      "pastel6" => ["#A1C9F4", "#8DE5A1", "#FF9F9B",
                    "#D0BBFF", "#FFFEA3", "#B9F2F0"].freeze,
      "bright" => ["#023EFF", "#FF7C00", "#1AC938", "#E8000B", "#8B2BE2",
                   "#9F4800", "#F14CC1", "#A3A3A3", "#FFC400", "#00D7FF"].freeze,
      "bright6" => ["#023EFF", "#1AC938", "#E8000B",
                    "#8B2BE2", "#FFC400", "#00D7FF"].freeze,
      "dark" => ["#001C7F", "#B1400D", "#12711C", "#8C0800", "#591E71",
                 "#592F0D", "#A23582", "#3C3C3C", "#B8850A", "#006374"].freeze,
      "dark6" => ["#001C7F", "#12711C", "#8C0800",
                  "#591E71", "#B8850A", "#006374"].freeze,
      "colorblind" => ["#0173B2", "#DE8F05", "#029E73", "#D55E00", "#CC78BC",
                       "#CA9161", "#FBAFE4", "#949494", "#ECE133", "#56B4E9"].freeze,
      "colorblind6" => ["#0173B2", "#029E73", "#D55E00",
                        "#CC78BC", "#ECE133", "#56B4E9"].freeze
    }.freeze

    MPL_QUAL_PALS = {
      "tab10" => 10,
      "tab20" => 20,
      "tab20b" => 20,
      "tab20c" => 20,
      "Set1" => 9,
      "Set2" => 8,
      "Set3" => 12,
      "Accent" => 8,
      "Paired" => 12,
      "Pastel1" => 9,
      "Pastel2" => 8,
      "Dark2" => 8,
    }.freeze

    QUAL_PALETTE_SIZES = MPL_QUAL_PALS.dup
    SEABORN_PALETTES.each do |k, v|
      QUAL_PALETTE_SIZES[k] = v.length
    end
    QUAL_PALETTE_SIZES.freeze

    def self.seaborn_colors(name)
      SEABORN_PALETTES[name].map do |hex_string|
        Charty::Colors::RGB.from_hex_string(hex_string)
      end
    end

    # Get a set of evenly spaced colors in HSL hue space.
    #
    # @param n_colors [Integer]
    #   The number of colors in the palette
    # @param h [Numeric]
    #   The hue value of the first color in degree
    # @param s [Numeric]
    #   The saturation value of the first color (between 0 and 1)
    # @param l [Numeric]
    #   The lightness value of the first color (between 0 and 1)
    #
    # @return [Array<Charty::Colors::HSL>]
    #   The array of colors
    def self.hsl_colors(n_colors=6, h: 3.6r, s: 0.65r, l: 0.6r)
      hues = Numo::DFloat.linspace(0, 1, n_colors + 1)[0...-1]
      hues.inplace + (h/360r).to_f
      hues.inplace % 1
      hues.inplace - Numo::Int32.cast(hues)
      (0...n_colors).map {|i| Charty::Colors::HSL.new(hues[i]*360r, s, l) }
    end

    def self.husl_colors(n_colors=6, h: 3.6r, s: 0.9r, l: 0.65r)
      raise NotImplementedError,
            "HUSL color palette has not been implemented"
    end

    def self.cubehelix_colors(n_colors, start=0, rot=0.4r, gamma=1.0r, hue=0.8r,
                               light=0.85r, dark=0.15r, reverse=false, as_cmap: false)
      raise NotImplementedError,
            "Cubehelix palette has not been implemented"
    end

    def self.matplotlib_colors(name, n_colors=6)
      raise NotImplementedError,
            "Matplotlib's colormap emulation has not been implemented"
    end

    # Return a list of colors defining a color palette
    #
    # @param palette [nil, String, Palette]
    #   Name of palette or nil to return current palette.
    #   If a Palette is given, input colors are used but
    #   possibly cycled and desaturated.
    # @param n_colors [Integer, nil]
    #   Number of colors in the palette.
    #   If `nil`, the default will depend on how `palette` is specified.
    #   Named palettes default to 6 colors, but grabbing the current palette
    #   or passing in a list of colors will not change the number of colors
    #   unless this is specified.  Asking for more colors than exist in the
    #   palette cause it to cycle.
    # @param desaturate_factor [Float, nil]
    #   Propotion to desaturate each color by.
    #
    # @return [Palette]
    #   Color palette.  Behaves like a list.
    def initialize(palette=nil, n_colors=nil, desaturate_factor=nil)
      case
      when palette.nil?
        @name = nil
        palette = Charty::Colors::ColorDate::DEFAULT_COLOR_CYCLE
        n_colors ||= palette.length
      else
        palette = normalize_palette_name(palette)
        case palette
        when String
          @name = palette
          n_colors ||= QUAL_PALETTE_SIZES.fetch(palette, 0)
          case @name
          when SEABORN_PALETTES.method(:has_key?)
            palette = self.class.seaborn_colors(@name)
          when "hls", "HLS", "hsl", "HSL"
            palette = self.class.hsl_colors(n_colors)
          when "husl", "HUSL"
            palette = self.class.husl_colors(n_colors)
          when "jet"
            # Paternalism
            raise ArgumentError,
                  "Don't use jet palette, " +
                  "see http://jakevdp.github.io/blog/2014/10/16/how-bad-is-your-colormap/"
          when /\Ach:/
            # Cubehelix palette with params specified in string
            args, kwargs = parse_cubehelix_args(palette)
            palette = self.class.cubehelix_colors(n_colors, *args, **kwargs)
          else
            begin
              palette = self.class.matplotlib_colors(palette, n_colors)
            rescue ArgumentError
              raise ArgumentError,
                    "#{palette} is not a valid palette name"
            end
          end
        else
          n_colors ||= palette.length
        end
      end
      if desaturate_factor
        palette = palette.map {|c| desaturate(c, desaturate_factor) }
      end

      # Always return as many colors as we asked for
      @colors = palette.cycle.take(n_colors).freeze
      @desaturate_factor = desaturate_factor
    end

    attr_reader :name, :colors, :desaturate_factor

    def n_colors
      @colors.length
    end

    def [](i)
      @palette[i % n_colors]
    end

    def to_ary
      @palette.dup
    end

    private def normalize_palette_name(palette)
      case palette
      when String
        palette
      when Symbol
        palette.to_s
      else
        palette.to_str
      end
    rescue NoMethodError, TypeError
      palette
    end
  end
end

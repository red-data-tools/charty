module Charty
  module Plotters
    class AbstractPlotter
      def initialize(x, y, color, **options)
        self.x = x
        self.y = y
        self.color = color
        self.data = data
        self.palette = palette
        substitute_options(options)

        @var_levels = {}
        @var_ordered = {x: false, y: false}

        yield self if block_given?
      end

      attr_reader :data, :x, :y, :color
      attr_reader :color_order, :key_color, :palette

      def var_levels
        variables.each_key do |var|
          # TODO: Move mappers from RelationalPlotter to here,
          #       and remove the use of instance_variable_get
          if instance_variable_defined?(:"@#{var}_mapper")
            mapper = instance_variable_get(:"@#{var}_mapper")
            @var_levels[var] = mapper.levels
          end
        end
        @var_levels
      end

      def inspect
        "#<#{self.class}:0x%016x>" % self.object_id
      end

      def data=(data)
        # TODO: Convert a Charty::Vector to a Charty::Table so that
        # the Charty::Vector is handled as a wide form data
        @data = case data
                when nil, Charty::Table
                  data
                when method(:array?)
                  Charty::Vector.new(data)
                else
                  Charty::Table.new(data)
                end
      end

      def x=(x)
        @x = check_dimension(x, :x)
      end

      def y=(y)
        @y = check_dimension(y, :y)
      end

      def color=(color)
        @color = check_dimension(color, :color)
      end

      def color_order=(color_order)
        @color_order = color_order
      end

      # TODO: move to categorical_plotter
      def key_color=(key_color)
        #@key_color = XXX
        unless key_color.nil?
          raise NotImplementedError,
                "Specifying key_color is not supported yet"
        end
      end

      def palette=(palette)
        @palette = case palette
                   when nil, Palette, Symbol, String
                     palette
                   else
                     raise ArgumentError,
                       "invalid type for palette (given #{palette.class}, " +
                       "expected Palette, Symbol, or String)"
                   end
      end

      attr_reader :x_label

      def x_label=(val)
        @x_label = check_string(val, :x_label, allow_nil: true)
      end

      attr_reader :y_label

      def y_label=(val)
        @y_label = check_string(val, :y_label, allow_nil: true)
      end

      attr_reader :title

      def title=(val)
        @title = check_string(val, :title, allow_nil: true)
      end

      private def substitute_options(options)
        options.each do |key, val|
          send("#{key}=", val)
        end
      end

      private def check_dimension(value, name)
        case value
        when nil, Symbol, String
          value
        when ->(x) { x.respond_to?(:to_str) }
          value.to_str
        when method(:array?)
          Charty::Vector.new(value)
        else
          raise ArgumentError,
                "invalid type of dimension for #{name} (given #{value.inspect})",
                caller
        end
      end

      private def check_number(value, name, allow_nil: false)
        case value
        when Numeric
          value
        else
          if allow_nil && value.nil?
            nil
          else
            expected = if allow_nil
                         "number or nil"
                       else
                         "number"
                       end
            raise ArgumentError,
                  "invalid value for #{name} (%p for #{expected})" % value,
                  caller
          end
        end
      end

      private def check_boolean(value, name, allow_nil: false)
        case value
        when true, false
          value
        else
          expected = if allow_nil
                       "true, false, or nil"
                     else
                       "true or false"
                     end
          raise ArgumentError,
                "invalid value for #{name} (%p for #{expected})" % value,
                caller
        end
      end

      private def check_string(value, name, allow_nil: false)
        case value
        when Symbol
          value.to_s
        else
          if allow_nil && value.nil?
            nil
          else
            orig_value = value
            value = String.try_convert(value)
            if value.nil?
              raise ArgumentError,
                "`#{name}` must be convertible to String: %p" % orig_value,
                caller
            else
              value
            end
          end
        end
      end

      private def variable_type(vector, boolean_type=:numeric)
        if vector.numeric?
          :numeric
        elsif vector.categorical?
          :categorical
        else
          case vector.iloc(0)
          when true, false
            boolean_type
          else
            :categorical
          end
        end
      end

      private def array?(value)
        TableAdapters::HashAdapter.array?(value)
      end

      private def remove_na!(ary)
        ary.reject! {|x| Util.missing?(x) }
        ary
      end

      private def each_subset(grouping_vars, reverse: false, processed: false, by_facet: true, allow_empty: false, drop_na: true)
        case grouping_vars
        when nil
          grouping_vars = []
        when String, Symbol
          grouping_vars = [grouping_vars.to_sym]
        end

        if by_facet
          [:col, :row].each do |facet_var|
            grouping_vars << facet_var if variables.key?(facet_var)
          end
        end

        grouping_vars = grouping_vars.select {|var| variables.key?(var) }

        data = processed ? processed_data : plot_data
        data = data.drop_na if drop_na

        if not grouping_vars.empty?
          grouped = data.group_by(grouping_vars, sort: false)
          grouped.each_group do |group_key, group_data|
            next if group_data.empty? && !allow_empty

            yield(grouping_vars.zip(group_key).to_h, group_data)
          end
        else
          yield({}, data.dup)
        end
      end

      def processed_data
        @processed_data ||= calculate_processed_data
      end

      private def calculate_processed_data
        # TODO: axis scaling support
        plot_data
      end

      def save(filename, **kwargs)
        backend = Backends.current
        call_render_plot(backend, notebook: false, **kwargs)
        backend.save(filename, **kwargs)
      end

      def render(notebook: false, **kwargs)
        backend = Backends.current
        call_render_plot(backend, notebook: notebook, **kwargs)
        backend.render(notebook: notebook, **kwargs)
      end

      private def call_render_plot(backend, notebook: false, **kwargs)
        backend.begin_figure
        render_plot(backend, notebook: notebook, **kwargs)
      end

      private def render_plot(*, **)
        raise NotImplementedError,
              "subclass must implement #{__method__}"
      end

      def to_iruby
        render(notebook: IRubyHelper.iruby_notebook?)
      end

      def to_iruby_mimebundle(include: [], exclude: [])
        backend = Backends.current
        if backend.respond_to?(:render_mimebundle)
          call_render_plot(backend, notebook: true)
          backend.render_mimebundle(include: include, exclude: exclude)
        else
          {}
        end
      end
    end
  end
end

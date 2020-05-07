class Utilibot < Tourmaline::Client
  macro params(name, *arguments)
    struct {{ name.id }}
      {% for arg in arguments %}
        {% if !arg.type %}
          {% raise "Arg #{arg.id} has no type" %}
        {% end %}
        getter {{ arg.var.id }} : {{ arg.type.id }}
      {% end %}

      def initialize({% for arg in arguments %}@{{ arg.var.id }}{% if arg.value %} = {{ arg.value }}{% end %},{% end %})
      end

      def self.parse(str : String)
        pieces = str.split(/\s+/)
        hash = pieces
          .map(&.split(':', 2).map(&.strip))
          .select(&.is_a?(Array))
          .to_h

        {% for arg in arguments %}
          {% type = arg.type.stringify.gsub(/ \| ::Nil/, "").id %}
          {% if arg.type.id.stringify.includes?("Nil") %}
            %tmp_{arg} = hash[{{ arg.var.id.stringify }}]?
            %var_{arg} = %tmp_{arg} ? {{ type }}.new(%tmp_{arg}) : nil
          {% else %}
            %tmp_{arg} = hash[{{ arg.var.id.stringify }}]
            %var_{arg} = {{ type }}.new(%tmp_{arg})
          {% end %}
        {% end %}

        new({% for arg in arguments %}{{ arg.var.id }}: %var_{arg},{% end %})
      end
    end
  end
end

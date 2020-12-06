require "json"

class Jekyll::Converters::Markdown::MarksiteProcessor
  def initialize(config)
    require "kramdown"
    @config = config
  end

  def slugify(s)
    s.downcase.gsub(/[^0-9a-z ]/i, "").strip.gsub(/\s+/, "-")
  end

  def convert(content)
    tree = parse(content)
    translate(tree)
  end

  def add_node(stack)
    node = []
    stack.last << node
    stack << node
  end

  def flush_buffer(buffer, stack)
    if not buffer.empty?
      stack.last << {
        id: slugify(buffer.first),
        content: buffer.join("")
      }
      buffer.clear
    end
  end

  def parse(content)
    tree = []
    stack = [tree]
    buffer = []

    content.each_line do |line|
      i = 0

      while line[i] == "#" do
        i = i + 1
      end

      # same
      if i > 0 and i == stack.size - 1 then
        flush_buffer(buffer, stack)
        stack.pop
        add_node(stack)

      # higher
      elsif i > 0 and i > stack.size - 1 then
        while i > stack.size - 1 do
          flush_buffer(buffer, stack)
          add_node(stack)
        end

      # lower
      elsif i > 0 and i < stack.size - 1 then
        flush_buffer(buffer, stack)

        # remove ((stack.size - 1) - i) nodes
        while stack.size - 1 >= i do
          stack.pop
        end

        add_node(stack)
      end

      # accumulate buffer
      buffer << line
    end

    flush_buffer(buffer, stack)

    tree
  end

  def translate_row(row, depth)
    buffer = ""

    row.each_with_index do | node, i |
      if node.is_a?(Hash) then
        buffer << Kramdown::Document.new(node[:content], auto_ids: false).to_html
        buffer << "<div class=\"container\">\n"
      else
        size = node.size - 1
        id = node.first.is_a?(Hash) ? "id=\"#{node.first[:id]}\"" : ""

        buffer << "<div #{id} class=\"depth-#{depth}\">\n"
        buffer << translate_row(node, depth + 1)
        buffer << "</div>\n"
      end
    end

    buffer << "</div>"

    buffer
  end

  def translate(tree)
    translate_row(tree, 1)
  end
end

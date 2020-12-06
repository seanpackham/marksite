module Jekyll
  module Converters
    module Markdown
    end
  end
end

require "./_plugins/marksite"

marksite = Jekyll::Converters::Markdown::MarksiteProcessor.new nil

puts marksite.convert File.open("README.md").read

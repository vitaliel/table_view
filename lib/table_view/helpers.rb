module TableView; end

module TableView::Helpers

  class TableViewTag
    include ActionView::Helpers::CaptureHelper

    def initialize(items)
      @table = TableView::Table.new(items)
    end

    def column(title, options = {}, &block)
      opts = {:display => proc { |row| capture(row, &block)}, :header => title}

      @table.add_column opts.update(options)
    end

    def to_s
      @table.to_s
    end
  end

  def table_view(items, &block)
    t = TableViewTag.new(items)
    block.call(t)
    concat(t.to_s, block.binding)
  end
end

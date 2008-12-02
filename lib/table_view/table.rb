module TableView; end

# TODO sum, count columns
# @deposits_table = TableView::Table.new(Account.deposits(@start_date), [
#                                      { :group => true, :value => Proc.new {|row| row.space }, :attr => {:class => 'group1'}},
#                                      { :header => "Buyer", :display => Proc.new {|acc| check_login acc.payer }, :cell_attr => {:align => :right}},
#                                      { :header => "Date", :display => Proc.new {|acc| acc.created_at.to_s :short }},
#                                      { :header => "Amount", :display => Proc.new {|acc| acc.amount }, :summary => :sum},
#                                     ])
# In views
# <%= @deposits_table %>
class TableView::Table
  attr_accessor :data, :columns, :groups, :has_summary, :visible_column_count

  include ActionView::Helpers::TagHelper

  def initialize(data, columns = [])
    self.data = data
    self.columns = columns
  end

  # :header => text, :type => :integer, :display => block(row)
  # :summary => summary function :sum, :avg
  def add_column(col)
    if col.is_a? Array
      self.columns += col
    else
      self.columns << col
    end
  end

  def header
    "<table><thead><tr>" + columns.map{ |c| c[:header] ? content_tag('th', c[:header]) : '' }.join('') + "</tr></thead>\n"
  end

  def row(row)
    rez = ''

    if groups.size > 0
      gr = groups[0]
      next_value = gr[:value].call(row)

      if next_value != gr[:current_value]
        # TODO calculate row count
        rez = tr(td(next_value, :colspan => visible_column_count), gr[:attr])
        gr[:current_value] = next_value
      end
    end

    rez + tr(columns.map{|col| cell(row, col)}.join(''))
  end

  def tr(str, attr = nil)
    content_tag('tr', str, attr) + "\n"
  end

  def td(str, attr = nil)
    content_tag 'td', str, attr
  end

  def cell(row, col)
    return unless col[:header]
    content = col[:display].call(row)

    if col[:summary]
      send("#{col[:summary]}_func", col, content)
    end

    td content.to_s, col[:cell_attr]
  end

  def footer
    rez = ''

    if has_summary && data.size > 1
      rez += '<tfoot><tr>' +
        columns.map{|col| td(col[:summary_value] ? '<b>' + col[:summary_value].to_s + '</b>': '&nbsp;')}.join +
        '</tr></tfoot>'
    end

    rez + "</table>"
  end

  def to_s
    if data.size > 0
      init_functions
      init_groups
      header + content_tag("tbody", data.map { |row| row(row)}.join('')) + footer
    else
      "<p class=\"no_records\">No records</p>"
    end
  end

  def init_groups
    self.groups = []

    for col in columns
      if col[:group]
        groups << {:value => col[:value], :current_value => :no_value, :row_count => 0, :attr => col[:attr] }
      end
    end
  end

  def init_functions
    self.visible_column_count = 0

    columns.each do |col|
      if col.has_key?(:display)
        self.visible_column_count += 1
      end

      if col[:summary] == :sum || col[:summary] == :avg
        col[:summary_value] = 0
        self.has_summary = true
      end
    end
  end

  def sum_func col, value
    col[:summary_value] += value
  end

  def avg_func col, value
    # TODO
  end
end

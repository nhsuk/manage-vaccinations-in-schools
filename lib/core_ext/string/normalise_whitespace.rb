# frozen_string_literal: true

class String
  # Normalises whitespace in a string by removing leading and trailing whitespace,
  # replacing multiple spaces with a single space, and returning nil if the result is empty.
  def normalise_whitespace
    # \u200D is a zero-width joiner (ZWJ) which is used in the frontend to display the NHS number
    strip.gsub(/\s+/, " ").gsub(/\u200D/, "").presence
  end

  def self.normalise_whitespace_sql(klass, database_column_name)
    # Equivalent to "regexp_replace(trim(#{database_column_name}), E'\\s+', ' ', 'g')"
    if klass.column_names.include?(database_column_name)
      Arel::Nodes::NamedFunction.new(
        "regexp_replace",
        [
          Arel::Nodes::NamedFunction.new(
            "trim",
            [klass.arel_table[database_column_name]]
          ),
          Arel::Nodes::SqlLiteral.new("E'\\s+'"),
          Arel::Nodes::SqlLiteral.new("' '"),
          Arel::Nodes::SqlLiteral.new("'g'")
        ]
      )
    else
      raise "Invalid column name: #{database_column_name}"
    end
  end
end

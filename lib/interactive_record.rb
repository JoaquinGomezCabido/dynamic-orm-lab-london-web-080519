require_relative "../config/environment.rb"
require 'active_support/inflector'

require 'pry'

class InteractiveRecord
    def self.table_name
        self.to_s.downcase.pluralize
    end
    
    def self.column_names
        sql = "PRAGMA table_info (#{table_name})"
        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |row|
            column_names << row["name"]
        end
        column_names.compact
    end
    
    def initialize(attributes={})
        attributes.each{|key, value| self.send("#{key}=", value)}
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def table_name_for_insert
        self.class.table_name
    end
    
    def values_for_insert
        values = []
        self.class.column_names.each do |column|
            values << "'#{send(column)}'" unless send(column).nil?
        end
        values.join(", ")
    end

    def col_names_for_insert
        self.class.column_names.delete_if{|column| column == "id"}.join(", ")
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end

    def self.find_by(hash)
        # sql = "SELECT * FROM #{table_name} WHERE ? IN #{column_names.split(", ")}"
        # DB[:conn].execute(sql, value)
        value = attribute_hash.values.first
        formatted_value = value.class == Fixnum ? value : "'#{value}'"
        sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{formatted_value}"
        DB[:conn].execute(sql)
    end
end

# binding.pry
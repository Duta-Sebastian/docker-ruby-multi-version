require 'json'

class LocalApp
  DATA_FILE = 'data.json'

  def initialize
    @data = load_data
  end

  def add_entry(name, value)
    @data[name] = value
    save_data
    puts "Entry added: #{name} -> #{value}"
  end

  def list_entries
    puts "Listing all entries:"
    @data.each do |name, value|
      puts "#{name}: #{value}"
    end
  end

  def find_entry(name)
    value = @data[name]
    if value
      puts "Found entry: #{name} -> #{value}"
    else
      puts "No entry found for #{name}"
    end
  end

  private

  def load_data
    if File.exist?(DATA_FILE)
      JSON.parse(File.read(DATA_FILE))
    else
      {}
    end
  end

  def save_data
    File.write(DATA_FILE, @data.to_json)
  end
end

app = LocalApp.new

# Example usage
app.add_entry('foo', 'bar')
app.add_entry('baz', 'qux')
app.list_entries
app.find_entry('foo')

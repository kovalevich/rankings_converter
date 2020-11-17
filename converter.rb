# frozen_string_literal: true

require 'json'

# Класс конвертера файла рэнкингов.
# Умеет сконвертировать файлик от утилиты rankings.rb и сохранить его в читаемом виде, или в формате json.
# Рэнкинги разбиваются по категориям и сортируются по значению рэнка
# Есть возможность отфильтровать выходные данные по категориям
# ВНИМЕНИЕ! лень разбираться, но корректно работает только если категории обрамляем двойными кавычками
# todo: Можно добавить фильтры по каличеству рэнков, по урлам, по рэнкам и т.д.
class Converter
  def initialize(categories, mode = [])
    @products = {}
    @mode = mode
    @mode[:random] = @mode[:random] == true ? 3 : @mode[:random].first.to_i unless @mode[:random].nil?
    @categories = categories
  end

  def convert(file)
    read_file file

    # разбиваю файл на путь и имя файла, затем снова собираю, добавив префикс к имени
    res = file.scan %r{^(.*/)?([^/]*)}
    res[0][1] = 'out_' + res[0][1]
    output_file = res[0].join
    output_file += '.json' if @mode[:json]

    output = @mode[:json] ? json : text
    write_to_file(output_file, output)
    puts "Job done! Output file: #{output_file}"
  end

  def write_to_file(file, text)
    File.open(file, 'w') { |f| f.write text }
  end

  def json
    filtered.to_json
  end

  def text
    categories = filtered

    txt = ''
    categories.each do |breadcrumb, products|
      txt += "#{breadcrumb}: \n"
      products.each { |p| txt += "\t#{prod_to_s(p)}\n" }
    end
    txt
  end

  def prod_to_s(prod)
    prod.values.join("\t")
  end

  def filtered
    data = @categories ? @products.dup.delete_if { |k, v| !@categories.include? k } : @products.dup

    data.each { |k, p| data[k] = p.sample(@mode[:random]) } if @mode[:random]
    sort(add_counters(data))
  end

  def add_counters(data)
    with_counters = {}

    data.each do |k, v|
      counters = " (products: #{v.size}/#{@products[k].size})"
      with_counters[k + counters] = v
    end
    with_counters
  end

  def sort(data)
    data.each { |category, products| data[category] = products.sort_by { |p| p[:rank] } }
  end

  def read_file(file)
    open file do |f|
      while (line = f.gets)
        product = line.split(/\t/)
        @products[product[1]] ||= []
        @products[product[1]] << { url: product[0], name: product[3], rank: product[2].to_i }
      end
    end
  end
end

def params
  help?
  unless ARGV.size.positive?
    puts 'Too few arguments'
    exit
  end
  mode = {
    json: param(%w[-j --json]),
    random: param(%w[-r --random])
  }
  [ARGV.shift, mode, param(%w[-c --categories])]
end

def param(names)
  return nil unless (ARGV & names).any?

  collection = []
  i = ARGV.find_index { |e| names.include? e }

  until ARGV[i + 1].nil? || ARGV[i += 1].scan(/^-/).any?
    collection << ARGV[i]
  end

  collection.any? ? collection : true
end

def help?
  return false unless (ARGV & %w[-h --help]).any?

  puts <<~HEREDOC
    Usage:
      ruby converter.rb <input_file> [options]
    
    Example:
      ruby converter.rb ./rankings.txt -c "Техника, электроника" "Техника, электроника *** Медтехника" --json
    
    Options:
      -c, --categories "cat1" "cat2"   filter output by categories
      -r, --random <number_rows (3)>   cut output to <number_rows> randomize rows
      -j, --json     json format output
      -h, --help     print help and exit
  HEREDOC
  exit
end

if __FILE__ == $PROGRAM_NAME
  file, mode, categories = params

  r = Converter.new(categories, mode)
  r.convert(file)
end

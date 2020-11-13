# frozen_string_literal: true

require 'json'

# Класс конвертера файла рэнкингов.
# Умеет сконвертировать файлик от утилиты rankings.rb и сохранить его в читаемом виде, или в формате json.
# Рэнкинги разбиваются по категориям и сортируются по значению рэнка
# Есть возможность отфильтровать выходные данные по категориям
# ВНИМЕНИЕ! лень разбираться, но корректно работает только если категории обрамляем двойными кавычками
# todo: Можно добавить фильтры по каличеству рэнков, по урлам, по рэнкам и т.д.
class Converter
  def initialize(categories, json = false)
    @products = {}
    @json = json
    @categories = categories
  end

  def convert(file)
    read_file file

    # разбиваю файл на путь и имя файла, затем снова собираю, добавив префикс к имени
    res = file.scan %r{^(.*/)?([^/]*)}
    res[0][1] = 'out_' + res[0][1]
    output_file = res[0].join
    output_file += '.json' if @json

    write_to_file output_file
    puts "Job done! Output file: #{output_file}"
  end

  def write_to_file(file)
    File.open(file, 'w') { |f| f.write to_s }
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

  def to_s
    categories = @categories ? @products.slice(*@categories) : @products
    return categories.to_json if @json

    text = ''
    categories.each do |breadcrumb, products|
      text += "#{breadcrumb} (#{products.size}): \n"
      products.sort_by { |p| p[:rank] }.each { |p| text += "\t#{p[:rank]}\t#{p[:url]}#{"\t" * 3}#{p[:name]}\n" }
    end
    text
  end
end

def params
  help?
  unless ARGV.size.positive?
    puts 'Too few arguments'
    exit
  end
  [ARGV.shift, (ARGV & %w[-j --json]).any?, categories_from_params]
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
      -j, --json     json format output
      -h, --help     print help and exit
  HEREDOC
  exit
end

def categories_from_params
  categories = []
  i = ARGV.find_index { |e| %w[-c --categories].include? e }
  return nil unless i

  until ARGV[i += 1].scan(/^-/).any?
    categories << ARGV[i]
    break unless ARGV[i + 1]
  end

  categories.any? ? categories : nil
end

if __FILE__ == $PROGRAM_NAME
  file, json, categories = params

  r = Converter.new(categories, json)
  r.convert(file)
end

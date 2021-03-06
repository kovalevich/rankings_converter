# Rankings Converter

Утилита генерит удобочитаемые файлы из файла вывода rankings.rb. Так же есть возможность отфильтровать результаты по категориям и сохранить все в формате json. Если не нужно выводить все данные, можно запускать с флагом -r \<number>. С этим флагом утилита выдаст только по \<number> случайных продуктов из каждой категории. 

```bash
ruby converter.rb -h
Usage:
  ruby converter.rb <input_file> [options]

Example:
  ruby converter.rb ./rankings.txt -c "Техника" "Техника *** Медтехника" --json

Options:
  -c, --categories "cat1" "cat2"   filter output by categories
  -r, --random <number_rows (3)>   cut output to <number_rows> randomize rows
  -j, --json     json format output
  -h, --help     print help and exit
```

## Как работать

Клонируем реп на свою машину, или в свою папку на шарде. Если на свой комп, то качаем файл с данными:

```sh
scp <шард>:/<path_to_remote_file> ./input.txt
```
Запускаем утилиту c необходимыми параметрами, или без:
```sh
ruby converter.rb ./input.txt --json
```
Выходной файл сохранится в директории входного файла, с префиксом 'out_'

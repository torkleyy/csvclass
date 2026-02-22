# csvclass

Little toy project for learning Zig.

## Goal

Take a `.csv` file and figure out its schema (fields, data types and optionality).

## Data types

- int
- float
- string
- bool

## Spec

This should be the output:

```txt
name,type,max_len,optional
col1,int,0,4,false
col2,string,8,12,true
```

## Benchmark

My naive implementation was able to run on https://www.datablist.com/learn/csv/download-sample-csv-files#download-customers-sample-csv-files customers-2000000.csv within 334 on 3800x with windows.

## License

MIT.

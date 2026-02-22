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

## License

MIT.

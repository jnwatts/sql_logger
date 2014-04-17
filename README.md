sql_logger
==========

Simple script which reads in an SQL file and executes each line separately, sending output optionally to a log file.

```
Usage: ./sql_logger.sh <options>
  --verbose|-v    Print output to screen and to output file
  --input|-i      File to read from, or "-" for stdin (default: "-")
  --output|-o     File to write to, or "-" for stdout (default: "-")
  --title|-t      Title to be output (default: "Homework")
  --author|-a     Author to be output (default: "")
  --user|-u       User to be output and used with psql (default: "jwatts")

  Example: ./sql_logger -i homework3.sql -o homework3_output.txt -a "Joe Student" -t "Homework
#3"
```

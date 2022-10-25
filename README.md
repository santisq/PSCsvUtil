<h1 align="center">PSCsvUtil</h1>

PS-CsvUtil is a tiny PowerShell Module composed of two functions to efficiently __split and merge__ big Csv files using [`StreamReader`](https://learn.microsoft.com/en-us/dotnet/api/system.io.streamreader.-ctor?view=net-7.0) and [`StreamWriter`](https://learn.microsoft.com/en-us/dotnet/api/system.io.streamwriter?view=net-7.0) .NET Classes.

## Compatibility

Tested and compatible with Windows PowerShell 5.1 and [PowerShell Core 7+](https://github.com/PowerShell/PowerShell).

## Examples

### Split a Csv into 5 chunks

This example demonstrates how to split a Csv using the `-Chunks` parameter from [`Split-Csv`](/public/Split-Csv.ps1).

```powershell
PS ..\PS-CsvUtil> gpstree .\tests\

Mode     Hierarchy                                   Size
----     ---------                                   ----
d----    tests                                       1.78 GB
-a---    └── bigcsv.csv                              1.78 GB

PS ..\PS-CsvUtil> Split-Csv .\tests\bigcsv.csv -DestinationFolder .\tests\by5chunks -PassThru -Chunks 5

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          10/16/2022  8:12 PM      382955825 bigcsv - Part 0.csv
-a---          10/16/2022  8:12 PM      382955849 bigcsv - Part 1.csv
-a---          10/16/2022  8:13 PM      382955817 bigcsv - Part 2.csv
-a---          10/16/2022  8:13 PM      382955855 bigcsv - Part 3.csv
-a---          10/16/2022  8:14 PM      382954454 bigcsv - Part 4.csv

PS ..\PS-CsvUtil> gpstree .\tests\

Mode     Hierarchy                                   Size
----     ---------                                   ----
d----    tests                                       1.78 GB
-a---    ├── bigcsv.csv                              1.78 GB
d----    └── by5chunks                               1.78 GB
-a---        ├── bigcsv - Part 0.csv                 365.22 MB
-a---        ├── bigcsv - Part 1.csv                 365.22 MB
-a---        ├── bigcsv - Part 2.csv                 365.22 MB
-a---        ├── bigcsv - Part 3.csv                 365.22 MB
-a---        └── bigcsv - Part 4.csv                 365.21 MB

PS ..\PS-CsvUtil> Import-Csv '.\tests\by5chunks\bigcsv - Part 3.csv' | Select-Object -First 3 | FT -Auto

Column0    Column1    Column2    Column3    Column4    Column5
-------    -------    -------    -------    -------    -------
2051598092 444770706  545010177  699773973  933288705  2135983609
649944517  1548086840 1011873614 1927411868 1902850446 240759930
182136426  1642338384 983474548  38656729   167556228  569658758
```

### Split a Csv into chunks of 250Mb

This example demonstrates how to split a Csv using the `-Size` parameter from [`Split-Csv`](/public/Split-Csv.ps1).

```powershell
PS ..\PS-CsvUtil> Split-Csv .\tests\bigcsv.csv -DestinationFolder .\tests\by50mbchunks -Size 50mb
PS ..\PS-CsvUtil> gpstree .\tests\by50mbchunks\

Mode     Hierarchy                                                        Size
----     ---------                                                        ----
d----    by50mbchunks                                                     1.78 GB
-a---    ├── bigcsv - Part 00.csv                                         50 MB
-a---    ├── bigcsv - Part 01.csv                                         50 MB
-a---    ├── bigcsv - Part 02.csv                                         50 MB
-a---    ├── bigcsv - Part 03.csv                                         50 MB
....
....
....
-a---    ├── bigcsv - Part 33.csv                                         50 MB
-a---    ├── bigcsv - Part 34.csv                                         50 MB
-a---    ├── bigcsv - Part 35.csv                                         50 MB
-a---    └── bigcsv - Part 36.csv                                         26.08 MB

PS ..\PS-CsvUtil> Import-Csv '.\tests\by50mbchunks\bigcsv - Part 28.csv' | Select-Object -First 3 | FT -Auto

Column0    Column1   Column2    Column3    Column4    Column5
-------    -------   -------    -------    -------    -------
1241863732 224211646 1035291147 1555398003 1777828960 416276892
1148375056 433051937 1367055122 556502602  38341193   113835498
2056137503 825665841 1921526568 2102926379 1093669865 2030084321
```

### Merging a split Csv

This example demonstrates how to merge the Csv files generated with the examples above using [`Merge-Csv`](/public/Merge-Csv.ps1).

```powershell
PS ..\PS-CsvUtil> Get-ChildItem .\tests\by50mbchunks\ -Filter *Part*.csv | Merge-Csv -DestinationPath mergedCsv50mbchunks.csv -PassThru

    Directory: D:\Zen\Documents\Scripts\pwsh\PS-CsvUtil

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          10/16/2022  8:32 PM     1914777556 mergedCsv50mbchunks.csv

PS ..\PS-CsvUtil> (Get-FileHash .\mergedCsv50mbchunks.csv -Algorithm MD5).Hash
0452ACEC1664A93137C41D131FA4C3A9

PS ..\PS-CsvUtil> (Get-FileHash .\tests\bigcsv.csv -Algorithm MD5).Hash
0452ACEC1664A93137C41D131FA4C3A9
```

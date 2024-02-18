# xlsx_compare
Comparing .xlsx files

# How to use
Just enter the original and the modified file as follows:
```sh
./xlsx_compare -o ../examples/files/data.xlsx -m ../examples/files/data2.xlsx
```

The execution shows the names of the filenames being compared. It start comparing the equally named sheets. It compares each sheet, column per column. So in the following example, you can see sheet named `Sheet1`. The first column `A` is being compared from both workbooks.
```txt
Comparing:
  - original file: ../examples/files/data.xlsx
  - modified file: ../examples/files/data2.xlsx


Worksheet: Sheet1
  A   |                    |  A   
------|====================|------
     1|The following table |
     2|Man-made object     |
     3|Luna 2              |
     4|Ranger 4            |
```
where:
- Left column shows the number when there is no change when compared with the other workbook.
```sh
     2|Man-made object     |
```
- A minus sign is shown in the left column when a line is removed from the original workbook:
```sh
   -33|Apollo 11 LM ascent |
```
- Right column is shown when a line is added in the modified workbook.
```sh
      |Otro                |12 
```
- The numbers in the left column represent the row from where that line is coming from in the original file. The numbers in the right column represent the row from where that line is coming in the modified file.


# Installation
If you have nim installed, you can just do:
```sh
nimble install https://github.com/mantielero/xlsx_compare
```

If not, you can download the binaries (for linux or windows) from the [releases](https://github.com/mantielero/xlsx_compare/releases) page.
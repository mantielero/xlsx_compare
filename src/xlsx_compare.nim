# nim c -r xlsx_compare.nim -o ../examples/files/data.xlsx -m ../examples/files/data2.xlsx
# nim c --os:windows --cc:clang --cpu:amd64 --clang.exe=zigcc --clang.linkerexe=zigcc --passC:"-target x86_64-windows -fno-sanitize=undefined" --passL:"-target x86_64-windows -fno-sanitize=undefined"   xlsx_compare.nim

# TODO: diferenciar hojas
import xl
import std/[strutils, tables, sequtils, strformat, editdistance, algorithm]
import experimental/diff
import system


proc getColumnsAsText(sheet:XlSheet):seq[string] =
  # convert a column to text
  for c in 0..<sheet.range.colCount:
    var col = sheet.col(c)
    var txt = ""
    for r in 0..<sheet.range.rowCount:
      var cell = col.cell(r)
      txt &= cell.value & "\n" 
    result &= txt

proc getColumnAsText(sheet:XlSheet;colNumber:int):tuple[txt:string,toRow:seq[int]] =
  # convert a column to text
  if colNumber > (sheet.range.colCount-1):
    raise newException(ValueError, "colNumber bigger than number of columns available")

  var col = sheet.col(colNumber)
  var txt = ""
  #var mapping = initTable[int, seq[string]]()
  var mapping:seq[int]

  for r in 0..<sheet.range.rowCount:
    var cell = col.cell(r)
    txt &= cell.value & "\n"
    mapping &= repeat(r, cell.value.splitLines.len)
  #echo mapping
  if txt.endsWith("\n"):
    txt = txt[0..<txt.high]
  return (txt,mapping)

proc myCmp(x, y: tuple[sheetName1:string, sheetName2:string, n:int]): int =
  cmp(x.n, y.n)

proc getSheetAsText(sheet:XlSheet):string =
  result = ""
  for r in 0..<sheet.range.rowCount:
    #var row = sheet.row(r)
    var txt = ""
    for c in 0..<sheet.range.colCount:
      #var cell = col.cell(r)
      txt &= sheet.cell(r,c).value & "|" 
    result &= txt & "\n"

#[ proc compareColumns2(col1,col2:tuple[txt:string; toRow:seq[int]]):string =
  var txt0 = col1.txt
  var txt1 = col2.txt
  #echo txt1
  var a = col1.txt.splitLines()
  var b = col2.txt.splitLines()
  var orig = 0

  for k in diffText(txt0, txt1):
    #echo ">>", k
    var
      startA = k.startA
      startB = k.startB
      deletedA = k.deletedA
      insertedB = k.insertedB
    for i in orig..<startA:
      result &= " |" & a[i] & "|\n"
      orig += 1

    for i in 0..<deletedA:
      result &= "-|" & a[startA+i] & "|\n"
      orig += 1

    for i in 0..<insertedB:
      result &= "+|" & b[startB+i] & "|\n"

  for i in orig..a.high:
    result &= " |" & a[i] & "|\n"  ]#


proc compareColumns(col1,col2:tuple[txt:string; toRow:seq[int]]):string =
  var txt0 = col1.txt
  var txt1 = col2.txt
  #echo txt1
  var a = col1.txt.splitLines()
  var b = col2.txt.splitLines()
  var orig = 0

  
  for k in diffText(txt0, txt1):
    var
      startA = k.startA
      startB = k.startB
      deletedA = k.deletedA
      insertedB = k.insertedB
    
    #echo ">>", k
    for i in orig..<startA:
      var nRow = col1.toRow[i] + 1
      result &=  &"{nRow:6.0}|{a[i]: <20.20}|\n" # &"{m:.<6.3}"
      orig += 1

    for i in 0..<deletedA:
      var nRow = -col1.toRow[startA+i] - 1
      result &= &"{nRow:6.0}|{a[startA+i]: <20.20}|\n"
      orig += 1

    for i in 0..<insertedB:
      var nRow = col2.toRow[startB+i] + 1
      result &= &"      |{b[startB+i]: <20.20}|{nRow:<5.0}\n"


  for i in orig..<a.high:
    var nRow = col1.toRow[i] + 1
    result &= &"{nRow:: <20.20}|" & a[i] & "|\n" 


proc compare(wbOriginal,wbModified: string) =
  var wb1 = xl.load(wbOriginal)
  var wb2 = xl.load(wbModified)

  # 1. Contar las hojas
  var wb1SheetNames = wb1.sheetNames.toSeq
  var wb2SheetNames = wb2.sheetNames.toSeq

  var sheetNames:seq[tuple[sheetName1:string, sheetName2:string, n:int]]
  var Nmax = 10000
  for name1 in wb1.sheetNames:
    var sheet1 = wb1.sheet(name1)
    var sheet1Txt = sheet1.getSheetAsText
    if sheet1Txt.len > Nmax:
      sheet1Txt = sheet1Txt[0..<Nmax]
    for name2 in wb2.sheetNames:
      var sheet2 = wb2.sheet(name2)
      var sheet2Txt = sheet2.getSheetAsText
      if sheet2Txt.len > Nmax:
        sheet2Txt = sheet2Txt[0..<Nmax]      

      sheetNames &= (name1, name2, editdistance(sheet1Txt, sheet2Txt))

  # Number of sheets that might have a match
  var n = min(wb1SheetNames.len, wb2SheetNames.len)
  sheetNames.sort(myCmp)

  # Show new Sheets
  if wb1SheetNames.len > wb2SheetNames.len:
    echo "\n\nThe original spreadsheet contains more sheets than modified one:"
    for tmp in sheetNames[n..sheetNames.high]:
      echo &"- {tmp.sheetName1}"
  elif wb2SheetNames.len > wb1SheetNames.len:
    echo "\n\nThe modified spreadsheet contains more sheets than original one:"
    for tmp in sheetNames[n..sheetNames.high]:
      echo &"- {tmp.sheetName2}"    

      

  # This is how sheetNames are traced from one file to another.
  #echo sheetNames[0..<n]

  # if wb1SheetNames.len > wb2SheetNames.len:
  #   echo &"[INFO] The original sheet has {wb1SheetNames.len - wb2SheetNames.len} sheets more than the modified one."

  # else:
  #   echo &"[INFO] The modifed sheet has {wb2SheetNames.len - wb1SheetNames.len} sheets more than the original one."

  #echo wb1SheetNames
  #echo wb2SheetNames  
  

  # 3. Dentro de cada hoja identificar si hay columnas de más

  for tmp in sheetNames[0..<n]:#wb1.sheetNames:
    echo "\n\nOriginal - Sheet Name: ", tmp.sheetName1
    echo "Modified - Sheet Name: ", tmp.sheetName2

    # Get columns
    var sheet1 = wb1.sheet(tmp.sheetName1)
    var sheet2 = wb2.sheet(tmp.sheetName2)    
    
    # Lets find which column is closer to the original (just in case it was reorder)
    var columns1 = sheet1.getColumnsAsText()
    var columns2 = sheet2.getColumnsAsText()

    var mapping:seq[tuple[i,j:int; item:seq[Item]]]
    for col1 in 0..columns1.high:
      var i = col1
      var j = 0
      var value = int.high
      var item:seq[Item]
      for col2 in 0..columns2.high:
        var tmp = diffText(columns1[col1], columns2[col2])
        var count = 0
        for n in tmp:
          count += n.deletedA 
          count += n.insertedB
        if count < value:
          value = count
          j = col2
          item = tmp
      mapping &= (i,j,item)

    # ==================================================================

    # Show differences
    for (i,j,items) in mapping:
      var colu1 = getColumnAsText(sheet1, i)
      var colu2 = getColumnAsText(sheet2, j)
      var colName1 = (row:0,col:i).name[0..^2]
      #var colName2 = (row:0,col:j).name[0..^2]      
      echo &"{colName1:^6}|{spaces(20)}|{colName1:^6}" # {repeat("", 25)}
      echo repeat("-",6),"|",repeat("=",20),"|",repeat("-",6)
      #echo ($i).c
      echo compareColumns(colu1,colu2)
      #break


proc xlsx_compare(original,modified:string) =
  ## ./xlsx_compare -o ../examples/files/data.xlsx -m ../examples/files/data2.xlsx 
  echo "Comparing:"
  echo "  - original file: ", original
  echo "  - modified file: ", modified
  compare(original, modified)

when isMainModule:
  import cligen
  dispatch xlsx_compare
  


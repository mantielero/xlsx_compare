version     = "0.1.0"
author      = "Jose Maria Garcia"
description = "Compares two .xlsx files showing values differences."
license     = "MIT"

# Deps

requires "nim >= 1.2.0"
requires "xl >= 1.0.0"
requires "cligen >= 1.6.18"

bin = @["xlsx_compare"]
srcDir = "src"

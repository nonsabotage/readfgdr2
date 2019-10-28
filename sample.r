# --------------------------------------------------------------------
# 基盤地図情報をsfオブジェクトに変換するスクリプト
# --------------------------------------------------------------------
# よく考えたらogr2ogrで簡単に変換ができたのであった・・・・
# ogr2ogr -f "ESRI Shapefile" -lco "ENCODING=UTF-8" a.shp FG-GML-563804-RdCompt-20180101-0001.xml

library(fs)
library(tidyverse)
library(here)
library(tictoc)
library(ggplot2)
source("R/readfgd.r", encoding = "UTF-8")

xmls <-
	"FG-GML-563804-ALL-20180101" %>%
	dir_ls(glob = "*/FG-GML-*.xml")
out <-
	xmls %>%
	path_file() %>%
	path(ext = "shp") %>%
	here("out", .)
# sfs <-
# 	xmls %>%
# 	map( ~ safely(readfgd)(.x, 4612)) %>%
# 	walk2(out, ~ st_write(.x$result, .y, layer_options = c("ENCODING=UTF-8"), delete_layer=TRUE))


# furrrを使っても早くならない・・・
# マージするコストが大きいのだろうか？
source("R/readfgd_dev.r", encoding = "UTF-8")

print(bench::mark(
	dev = readfgd_dev("FG-GML-563804-ALL-20180101/FG-GML-563804-BldA-20180101-0001.xml", 4612)
))

gc();gc();

source("R/readfgd.r", encoding = "UTF-8")
print(bench::mark(
	org = readfgd("FG-GML-563804-ALL-20180101/FG-GML-563804-BldA-20180101-0001.xml", 4612),
	lib = fgdr::read_fgd("FG-GML-563804-ALL-20180101/FG-GML-563804-BldA-20180101-0001.xml"),
	check = FALSE
))
# tibble: 2 x 14
#   expression    min   mean median    max
#   <chr>      <bch:> <bch:> <bch:> <bch:>
# 1 org        55.73s 55.73s 55.73s 55.73s
# 2 lib         1.39m  1.39m  1.39m  1.39m


target <- "FG-GML-563804-ALL-20180101/FG-GML-563804-BldA-20180101-0001.xml"
target <- "FG-GML-563804-ALL-20180101/FG-GML-563804-AdmPt-20180101-0001.xml"
target <- "FG-GML-563804-ALL-20180101/FG-GML-563804-WL-20180101-0001.xml"

tic()
readfgd(target, 4612)
toc()

tic()
readfgd_dev(target, 4612)
toc()

tic()
fgdr::read_fgd(target)
toc()


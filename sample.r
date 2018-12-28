# --------------------------------------------------------------------
# 基盤地図情報をsfオブジェクトに変換するスクリプト
# --------------------------------------------------------------------
# よく考えたらogr2ogrで簡単に変換ができたのであった・・・・
# ogr2ogr -f "ESRI Shapefile" -lco "ENCODING=UTF-8" a.shp FG-GML-563804-RdCompt-20180101-0001.xml

library(fs)
library(tidyverse)
library(here)
library(tictoc)
source("R/readfgd_dev.r", encoding = "UTF-8")

xmls <-
	"FG-GML-563804-ALL-20180101" %>%
	dir_ls(glob = "*/FG-GML-*.xml")
out <-
	xmls %>%
	path_file() %>%
	path(ext = "shp") %>%
	here("out", .)
sfs <-
	xmls %>%
	map( ~ safely(readfgd)(.x, 4612)) %>%
	walk2(out, ~ st_write(.x$result, .y, layer_options = c("ENCODING=UTF-8"), delete_layer=TRUE))


# furrrを使っても早くならない・・・
# マージするコストが大きいのだろうか？
source("R/readfgd_dev.r", encoding = "UTF-8")
bench::mark(
	dev = readfgd("FG-GML-563804-ALL-20180101/FG-GML-563804-BldA-20180101-0001.xml", 4612)
)

source("R/readfgd.r", encoding = "UTF-8")
bench::mark(
	org = readfgd("FG-GML-563804-ALL-20180101/FG-GML-563804-BldA-20180101-0001.xml", 4612)
)


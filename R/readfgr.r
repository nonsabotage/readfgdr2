library(xml2)
library(fs)
library(sf)
library(tidyverse)

pos_to_multipolygon <- function (poslist_) {
	poslist_ %>%
	scan(text = ., what = numeric(0), quiet = TRUE) %>%
	matrix(ncol = 2, byrow = TRUE) %>%
	"["( , c(2, 1)) %>% # 経度, 緯度の順番に直す
	list() %>%
	st_polygon() %>%
	list() %>%
	st_multipolygon()
}
pos_to_linestring <- function (postlist_) {
	postlist_ %>%
	scan(text = ., what = numeric(0), quiet = TRUE) %>%
	matrix(ncol = 2, byrow = TRUE) %>%
	"["( , c(2, 1)) %>% # 経度, 緯度の順番に直す
	st_linestring()
}
pos_to_point <- function (pos_) {
	pos_ %>%
	scan(text = ., what = numeric(0), quiet = TRUE) %>%
	rev() %>% # 経度, 緯度の順番に直す
	st_point()
}
geonode_to_geometry <- function (geonode_, num_epsg_, path_pos_, converter_) {
	geonode_ %>%
	xml_find_first(path_pos_) %>%
	xml_text() %>%
	map( ~ converter_(.x)) %>%
    st_sfc(crs = num_epsg_)
}
geo2multipoly <-
	partial(
		geonode_to_geometry,
		path_pos_  = "./gml:Surface/gml:patches/gml:PolygonPatch/gml:exterior/gml:Ring/gml:curveMember/gml:Curve/gml:segments/gml:LineStringSegment/gml:posList",
		converter_ = pos_to_multipolygon
	)
geo2line <-
	partial(
		geonode_to_geometry,
		path_pos_  = "./gml:Curve/gml:segments/gml:LineStringSegment/gml:posList",
		converter_ = pos_to_linestring
	)
geo2point <-
	partial(
		geonode_to_geometry,
		path_pos_  = "./gml:Point/gml:pos",
		converter_ = pos_to_point
	)
readfgdr <- function (fgdr_xml_file_, num_epsg_) {

	fgdr_class <-
		fgdr_xml_file_ %>%
		path_file() %>%
		str_split("-") %>%
		flatten_chr() %>%
		purrr::pluck(4) # マジックナンバーなので正規表現で書き直したい・・・・

	# parse xml
	parsed_xml <-
		fgdr_xml_file_ %>%
		read_xml()

	# node name
	# 名前空間の解決にxml_ns_strip()を使うことができるが計算コストが高い
	# 名前空間は直接指定すること
	path_data_node  <- sprintf("/d1:Dataset/d1:%s[1]/child::*", fgdr_class)
	data_node_names <-
		parsed_xml %>%
		xml_find_all(path_data_node) %>%
		xml_name()
	geometry_node_index  <- grep("area|loc|pos", data_node_names)
	geometry_node_name   <- data_node_names[ geometry_node_index]
	ungeometry_node_name <- data_node_names[-geometry_node_index]

	# glmid
	path_class <- sprintf("/d1:Dataset/d1:%s", fgdr_class)
	class_node <- parsed_xml %>% xml_find_all(path_class)
	gmlid <-
		class_node %>%
		xml_attr("id") %>%
		list(gmlid = .)

	# ungeometry_attr
	path_ungeometry_node  <- sprintf("./d1:%s", ungeometry_node_name)
	ungeometry_node_value <-
		path_ungeometry_node %>%
		# 属性ノードが欠落している場合があるのでxml_find_allを使わない
		# クラスノードと同じ数が返されるxml_find_firstを使う
		map( ~ xml_find_first(class_node, .x)) %>%
		map( ~ xml_text(.x)) %>%
		set_names(ungeometry_node_name)

	# geometry
	convert_geonode_to_geometry <-
		geometry_node_name %>%
		switch(
			area = geo2multipoly,
			loc = geo2line,
			pos = geo2point,
			stop(sprintf("%s : 見慣れない形状タイプですね", geometry_node_name))
		)
	path_geonode  <- sprintf("./d1:%s", geometry_node_name)
	geometry_node <- xml_find_first(class_node, path_geonode)
	geometry      <- convert_geonode_to_geometry(geonode_ = geometry_node, num_epsg_ = num_epsg_)


	res <- bind_cols(c(gmlid, ungeometry_node_value))
	st_geometry(res) <- geometry
	res

}

# readfgdr

国土地理院では基盤地図情報をXMLで提供しています.
ここでは基盤地図情報のうちDEM以外のデータをsfオブジェクトで
読み込むための関数です.

なお本来はogr2ogrでxmlをshpに変換してから`sf::st_read`等を
活用する方が早いです．

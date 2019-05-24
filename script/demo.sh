mysql -udata_display -pdata_display7xKbcbOdC2UOqy0z -h172.16.8.5 -P3308 -A warehouse -e 'select * from query_prediction' > /data1/zhouxiangjun/query_tagging/data/query_prediction.mysql.bak
mysql -udata_display -pdata_display7xKbcbOdC2UOqy0z -h172.16.8.5 -P3308 -A warehouse -e 'select * from query_prediction' > /data1/zhouxiangjun/query_tagging/data/qt_prediction.mysql.20181220

mysql -udata_display -pdata_display7xKbcbOdC2UOqy0z -h172.16.8.5 -P3308 -A warehouse -e 'select * from query_tagging' > /data1/zhouxiangjun/query_tagging/data/qt_query_tagging.mysql.bak
mysql -udata_display -pdata_display7xKbcbOdC2UOqy0z -h172.16.8.5 -P3308 -A warehouse -e 'select * from query_tagging' > /data1/zhouxiangjun/query_tagging/data/qt_query_tagging.mysql.20181220

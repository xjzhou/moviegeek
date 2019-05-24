#!/bin/bash

:<< 注释
*******************************
如果三月播种,九月将有收获,
焦虑的人啊,请你不要守着四月的土地哭泣。
土地已经平整,种子已经发芽,
剩下的事情交给时间来完成
*******************************

Usage: 

*******************************
注释


cd `dirname $0`

TEST=0
[[ -z "$1" ]] && export CURRENT_DATE=`date +%Y-%m-%d --date="1 day ago"` || export CURRENT_DATE=$1  #2018-12-18

source ../conf/main.conf
source /data/task/algo_common/util.sh
source /data/task/algo_common/util_ex.sh
source /data/pyspark/pyspark2/bin/activate

#
# 包括
# （1）参数检查
# （2）字典数据检查
# （3）依赖目录文件检查
# （4）环境变量检查
#
check_precondition()
{
    log_info "$FUNCNAME::begin"

    cmd="echo"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    echo -e "请做好: \n \
（1）参数检查 \n \
（2）字典数据检查 \n \
（3）依赖目录文件检查 \n \
（4）环境变量检查 \n"


    log_info "$FUNCNAME::successed"
    return 0
}


#
# 删除过期数据
#
delete_expired_data()
{
    log_info "$FUNCNAME():: begin"
    log_info "......."
    log_info "$FUNCNAME():: finished"
    return 0

    # delete hdfs old files
    for((i=${HDFS_PRESERVE_DAYS};i<${HDFS_PRESERVE_DAYS}+3;i++))
    do
        local tmp_date=`date -d "$CURRENT_DATE $i days ago" +"%Y%m%d"`
        cmd="hadoop_secure_rmr ${HFS_WORK_HOME}/${tmp_date}"
        log_info $cmd
        eval $cmd
        [ $? -ne 0 ] && return 1

        hadoop_secure_rmr ${HFS_WORK_HOME}/${tmp_date}.done
    done

    #delete local old files

    log_info "$FUNCNAME():: finished"
    return 0
}

#    '''
#    df_querylog  = spark.sql(querylog_category).toPandas()
#    df_category  = spark.sql(category).toPandas()
#    df_craftsma  = spark.sql(craftsman).toPandas()
#    df_attribute = spark.sql(atrribute).toPandas()
#
#    logger.info('df_querylog:', df_querylog.shape, 
#          'df_category:', df_category.shape, 
#          'df_craftsma:', df_craftsma.shape, 
#          'df_attribute:', df_attribute.shape)
#    return df_querylog, df_category, df_craftsma, df_attribute
#    '''

#
# qt 获取计算依赖字典数据
#
qt_get_dependent_dict()
{
    log_info "$FUNCNAME::begin"

    qt_data_tmp=${LOCAL_DATA_HOME}/tmp

    _tb_name=craftsman
    _file=${qt_data_tmp}/${_tb_name}.utf8
    rm -f ${_file}
    cmd="hadoop_getmerge ${HIVE_QT_DB}/${_tb_name} ${_file}"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    check_txt_file_min_lines ${_file} 100
    [[ $? -ne 0 ]] && return 1

    _tb_name=iid_query_pv_category
    _file=${qt_data_tmp}/${_tb_name}.utf8
    rm -f ${_file}
    cmd="hadoop_getmerge ${HIVE_QT_DB}/${_tb_name} ${_file}"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    check_txt_file_min_lines ${_file} 10000
    [[ $? -ne 0 ]] && return 1

    _tb_name=iid_query_pv
    _file=${qt_data_tmp}/${_tb_name}.utf8
    rm -f ${_file}
    cmd="hadoop_getmerge ${HIVE_QT_DB}/${_tb_name} ${_file}"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    check_txt_file_min_lines ${_file} 10000
    [[ $? -ne 0 ]] && return 1

    _tb_name=category
    _file=${qt_data_tmp}/${_tb_name}.utf8
    rm -f ${_file}
    cmd="hadoop_getmerge ${HIVE_QT_DB}/${_tb_name} ${_file}"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1


    check_txt_file_min_lines ${_file} 100
    [[ $? -ne 0 ]] && return 1

    _tb_name=attribute
    _file=${qt_data_tmp}/${_tb_name}.utf8
    rm -f ${_file}
    cmd="hadoop_getmerge ${HIVE_QT_DB}/${_tb_name} ${_file}"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    check_txt_file_min_lines ${_file} 10000
    [[ $? -ne 0 ]] && return 1

    log_info "$FUNCNAME::successed"
    return 0
}




#
#
#
parse_userlog()
{
    log_info "$FUNCNAME::begin"

    local dir_input=${HFS_USER_LOG_IN}
    local dir_output=${HFS_USER_LOG_OUT}

    # 通过检查上游文件数量判断上游是否ready
    hadoop_get_file_count ${dir_input}
    [[ $? -ne 0 ]] && return -1
    if [ ${HADOOP_FILE_COUNT} -ne ${HFS_USER_LOG_IN_NUM} ] 
    then
        log_error "${FUNCNAME}::failed, ${dir_input} count != ${HFS_USER_LOG_IN_NUM}";
        return -1;
    fi
     
    ${HADOOP_EXEC} fs -rmr ${HFS_USER_LOG_OUT}.done
    ${HADOOP_EXEC} fs -rmr ${HFS_USER_LOG_OUT}
    cmd="${HADOOP_EXEC} jar ${JAR_DIST} com.taobaosc.cvr.UserLogParser \
    -Dmapred.output.compress=true \
    -Dmapred.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec \
    -i ${HFS_USER_LOG_IN} \
    -o ${HFS_USER_LOG_OUT} \
    -r 50"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return -1
    ${HADOOP_EXEC} fs -touchz ${HFS_USER_LOG_OUT}.done

    log_info "$FUNCNAME::successed"
    return 0
}




#
# http://cf.idongjia.cn/pages/viewpage.action?pageId=17925324
# 数据提取: src/qt_data_prepare.py 
# 数据处理：src/qt_data_process.py
# 预测: query_pre_tagging.py
#
qt_gen_input_table()
{
    log_info "$FUNCNAME::begin"

    cmd="${SPARK_SUBMIT} --master yarn --queue pyspark \
    --num-executors 2 \
    --executor-cores 1 \
    --name ${PROJECT_NAME}  \
    ${LOCAL_WORK_HOME}/src/${FUNCNAME}.py"

    log_info $cmd
    eval $cmd
    if [[ $? -ne 0 ]]; then
        log_error "$FUNCNAME::failed"
        return 1
    fi 

    log_info "$FUNCNAME::successed"
    return 0
}



qt_processing()
{
    log_info "$FUNCNAME::begin"


    cmd="${PYTHON_EXEC} ${LOCAL_WORK_HOME}/src/${FUNCNAME}.py"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    log_info "$FUNCNAME::successed"
    return 0
}

add_w2v_to_query_tagging()
{
    log_info "$FUNCNAME::begin"

    cmd="${PYTHON_EXEC} ${LOCAL_WORK_HOME}/src/${FUNCNAME}.py"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    log_info "$FUNCNAME::successed"
    return 0
}


#
#
#
process_title()
{
    log_info "$FUNCNAME::begin"
    my_sql=${LOCAL_WORK_HOME}/src/process_title.sql
    cmd="${CC_HIVE} -p ds=${CURRENT_DATE} -f ${my_sql}"
    log_info $cmd
    eval $cmd
    if [[ $? -ne 0 ]]; then
        log_error "$FUNCNAME::failed"
        return 1
    fi  

    # 
    tmp_item_info_hdfs="/user/hive/warehouse/zhl.db/tmp_item_info"
    tmp_item_info_file=${LOCAL_WORK_HOME}/data/iid_category_info.utf8

    rm -f ${tmp_item_info_file}
    cmd="hadoop_getmerge ${tmp_item_info_hdfs} ${tmp_item_info_file}"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    tmp_dim_segmented_items_file="${LOCAL_WORK_HOME}/data/dim_segmented_items.csv"
    cmd="${PYTHON_EXEC} ${LOCAL_WORK_HOME}/src/item_w2v.py ${tmp_item_info_file} ${tmp_dim_segmented_items_file}"
    log_info $cmd
    eval $cmd
    [[ $? -ne 0 ]] && return 1

    # 
    tmp_dim_segmented_items_hdfs="/zhongling/items/dim_segmented_items/data.csv"
    hadoop_rmr ${tmp_dim_segmented_items_hdfs}
    hadoop_put ${tmp_dim_segmented_items_file} ${tmp_dim_segmented_items_hdfs}

    log_info "$FUNCNAME::successed"
    return 0
}


#
#
#
main()
{
    log_info "${FUNCNAME}::begin"

    check_precondition
    [[ $? -ne 0 ]] && return 1

    delete_expired_data
    [[ $? -ne 0 ]] && return 1

    #####  这两句为了避免测试误操作 ####
    #log_info "${FUNCNAME}::successed"
    #return 0
    ###################################  

    qt_gen_input_table
    [[ $? -ne 0 ]] && return 1

    qt_get_dependent_dict
    [[ $? -ne 0 ]] && return 1

    qt_processing
    [[ $? -ne 0 ]] && return 1

    add_w2v_to_query_tagging
    [[ $? -ne 0 ]] && return 1

    process_title
    [[ $? -ne 0 ]] && return 1

    log_info "${FUNCNAME}::successed"
    return 0
}

######################### program entry ##############################
mkdir -p `dirname ${LOG_FILE_PATH}`

if [[ $TEST -eq 0 ]]
then
    main >> ${LOG_FILE_PATH} 2>&1
else
    main 
fi

#
# 如果程序出错邮件通知
#
if [ $? -ne 0 ]
then

#`which sendmail` -t ${MAIL_ALERT_LIST} <<EMAIL
#To: ${MAIL_ALERT_LIST}
#Reply-To: ${MAIL_ALERT_LIST}
#Subject:  ${MAIL_SUBJECT}
#Mime-Version: 1.0
#Content-Type: text/html; charset=utf-8
#<html><body><hr> <pre> `tail -10 ${LOG_FILE_PATH}` </pre> </p> <hr></body></html>
#EMAIL

    log_error "【这儿需要添加邮件报警】"

    exit 1
fi

exit 0

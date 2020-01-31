#!/bin/bash -x
##################################################################
# Copyright (c) Diyotta Inc. All rights reserved.                #
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.  #
#                                                                #
# This source file is proprietary property of Diyotta, Inc.      #
# This code is cannot be copied and/or redistributed and/or      #
# modified without prior permission from  Diyotta.               #
# Please contact us at contact@diyotta.com or                    #
# visit www.diyotta.com you need additional information.         #
##################################################################
#Sourcing environmental variables
source $DI_HOME/support/conf/env.properties

. ${di_lib}/migration/diy_functions.sh

#Send error message and exit if required arguments are not passed
if [[ $# -lt 4 ]]; then
   echo "Usage : diy_import.sh <git location> <git branch> <migration list file> <temp location> "
   exit 1
fi

git_location=$1
git_branch=$2
list_file=$3
tmp_location=$4
new_project_name=$5

logfile_location=${di_log}
log_filename=${logfile_location}/import_`date +"%d%m%Y%H%M"`.log

#Write all the output in the log file
exec | tee $log_filename

#Skip the first line(header) from the export list file
sed '1d' $list_file > ${tmp_location}/import.lst

#Assign source repository location to a variable
source_location=$git_location
tmp_home=${tmp_location}
src_diyotta_loc=$source_location/diyotta

cd $source_location
fn_chkstatus $? "cd to target - $source_location unsuccessful"

git checkout $git_branch 2>&1
fn_chkstatus $? "Git checkout - $git_branch unsuccessful"

git pull -q origin $git_branch 2>&1

#Remove temp file if it already exist
fn_rmfile $tmp_home/tmp_import_dicmd.lst

#Loop through the import list and return error message if any
while read -r line
do
        imptype=`echo $line | cut -d ',' -f1`
        import_object_type=$(fn_uppercase $imptype)

        objname=`echo $line | cut -d ',' -f2`
        import_object_name=$(fn_lowercase $objname)

        prj=`echo $line | cut -d ',' -f3`
        project_name=$(fn_uppercase $prj)

        layer=`echo $line | cut -d ',' -f4`
        layer_name=$(fn_lowercase $layer)

        dtpoint=`echo $line | cut -d ',' -f5`
        data_point=$(fn_lowercase $dtpoint)

        grpname=`echo $line | cut -d ',' -f6`
        group_name=$(fn_lowercase $grpname)

        objtype=`echo $line | cut -d ',' -f7`
        object_type=$(fn_uppercase $objtype)

if [[ ! "$import_object_type" =~ ^(PROJECT|LAYER|JOBFLOW|DATAFLOW|DOBJ|DATAPOINT)$ ]];
then
        echo "Only below object can be imported:"
        echo "          project   - to import entire project"
        echo "          layer     - to import entire layer"
        echo "          jobflow   - to import jobflow"
        echo "          dataflow  - to import dataflow"
        echo "          dobj      - to import dobj"
        echo "          datapoint - to import datapoint"
        exit 1
fi

if [[ "$import_object_type" =~ ^(DOBJ|DATAPOINT)$ ]];
then
        if [[ ! "$object_type" =~ ^(SN|SS|OR|FF|PG|MS|JS|RT|TD|NZ)$ ]];
        then
                echo "Object type should be one of the below:"
                echo "          SN - Snowflake"
                echo "          SS - Sqlserver"
                echo "          OR - Oracle"
                echo "          FF - FlatFile"
                echo "          PG - POSTGRESQL"
                echo "          MS - MSSQL"
                echo "          JS - JSON"
                echo "          RT - REST"
                echo "          TD - Teradata"
                echo "          NZ - Netezza"
                exit 1
        fi
fi

#Check the project directory exists, if not send error message
if [ "$import_object_type" == "PROJECT" ]
then
        project_dir=$(fn_uppercase $import_object_name)
else
        project_dir=$project_name
fi

#call function to send error message if not exist
fn_checkdir ${src_diyotta_loc}/${project_dir}

if [ "$import_object_type" == "PROJECT" ]
then
        prj_dir=$(fn_uppercase $import_object_name)
        filename="${src_diyotta_loc}/${prj_dir}/project/${import_object_name}.json"

                #call function to send error message if directory not exist
                fn_checkdir ${src_diyotta_loc}/${prj_dir}/project

        if [[ -z $import_object_name ]];
        then
                fn_missingargs $import_object_type "To Import - import_Object_Name is Mandatory"
        fi

        echo "dicmd import -p $prj_dir -f $filename" >> $tmp_home/tmp_import_dicmd.lst

elif [ "$import_object_type" == "LAYER" ]
then
        filename="${src_diyotta_loc}/${project_name}/layer/${import_object_name}.json"

                #call function to create directory if not exist
                fn_checkdir ${src_diyotta_loc}/${project_name}/layer

        if [[ -z $project_name || -z $import_object_name ]];
        then
                fn_missingargs $import_object_type "To Import - import_Object_Name and Project are Mandatory details"
        fi
        echo "dicmd import -p $project_name -l $import_object_name -f $filename" >> $tmp_home/tmp_import_dicmd.lst

elif [ "$import_object_type" == "JOBFLOW" ]
then
        filename="${src_diyotta_loc}/${project_name}/jobflow/${layer_name}/${import_object_name}.json"

                #call function to create directory if not exist
                fn_checkdir ${src_diyotta_loc}/${project_name}/jobflow/${layer_name}

        if [[ -z $project_name || -z $import_object_name || -z $layer_name ]];
        then
                fn_missingargs $import_object_type "To Import - import_Object_Name,layer and Project are Mandatory details"
        fi
        echo "dicmd import -p $new_project_name -f $filename" >> $tmp_home/tmp_import_dicmd.lst

elif [ "$import_object_type" == "DATAFLOW" ]
then
        filename="${src_diyotta_loc}/${project_name}/dataflow/${layer_name}/${import_object_name}.json"

                #call function to create directory if not exist
                fn_checkdir ${src_diyotta_loc}/${project_name}/dataflow/${layer_name}

        if [[ -z $project_name || -z $import_object_name || -z $layer_name ]];
        then
                fn_missingargs $import_object_type "To Import DATAFLOW - import_Object_Name,layer and Project are Mandatory details"
        fi
        echo "dicmd import -p $project_name -f $filename" >> $tmp_home/tmp_import_dicmd.lst

elif [ "$import_object_type" == "DOBJ" ]
then
        filename="${src_diyotta_loc}/${project_name}/dataobject/${group_name}/${data_point}_${group_name}_${import_object_name}.json"

                #call function to create directory if not exist
                fn_checkdir ${src_diyotta_loc}/${project_name}/dataobject/${group_name}

        if [[ -z $project_name || -z $data_point || -z $group_name || -z $import_object_name ]];
        then
                fn_missingargs $import_object_type "To Import DOBJ - import_Object_Name,project,Datapoint and Group are Mandatory details"
        fi
        echo "dicmd import -p $project_name -f $filename" >> $tmp_home/tmp_import_dicmd.lst

elif [ "$import_object_type" == "DATAPOINT" ]
then
        obj_type=$(fn_lowercase $object_type)
        filename="${src_diyotta_loc}/${project_name}/datapoint/${group_name}/${obj_type}_${group_name}_${import_object_name}.json"

                #call function to create directory if not exist
                fn_checkdir ${src_diyotta_loc}/${project_name}/datapoint/${group_name}

        if [[ -z $project_name || -z $object_type || -z $group_name || -z $import_object_name ]];
        then
                fn_missingargs $import_object_type "To Import DATAPOINT - import_Object_Name,project,Group and Object_type are Mandatory details"
        fi
        echo "dicmd import -p $project_name -f $filename" >> $tmp_home/tmp_import_dicmd.lst

else
        echo "Invalid import_object_type"
fi

done < $tmp_home/import.lst


#Loop through all the dicmd import command generated and import the objects
while read -r line
do
        filename=`echo $line | rev | cut -d'/' -f1 | rev`
        echo "Importing: $filename "
        op_message=`$line 2>&1`

                 if [ $? != 0 ]; then
                        echo -e "Import $filename- unsuccessful \n \t $op_message"
                        exit 1
                else
                        echo "Import $filename - Successfully completed"
                fi
done < $tmp_home/tmp_import_dicmd.lst

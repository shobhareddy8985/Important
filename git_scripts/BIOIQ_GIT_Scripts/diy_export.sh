#!/bin/bash
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
#Sourcing environmental variables.
source $DI_HOME/support/conf/env.properties

. ${di_lib}/migration/diy_functions.sh

#Send error message and exit if required arguments are not passed
if [[ $# -lt 6 ]]; then
   echo "Usage : diy_export.sh <list file> <git home location> <git main branch> <git release branch> <temp location> <git commit message>"
   exit 1
fi

#Assign variables for all input arguments
list_file=$1
git_location=$2
git_branch=$3
release_branch=$4
tmp_location=$5
commit_msg=$6

#Skip the first line(header) from the export list file
sed '1d' $list_file > ${tmp_location}/export.lst

#Assign the git repository location and branch name to a variable
target_location=$git_location
tmp_home=$tmp_location
tgt_diyotta_loc=$target_location/diyotta

#Remove temp file if it already exist
fn_rmfile $tmp_home/tmp_export_dicmd.lst

#Checkout the git branch and create release git branch to add the files exported
cd $target_location
fn_chkstatus $? "cd to target - $target_location unsuccessful"

git checkout -q $git_branch
fn_chkstatus $? "Git checkout - $git_branch unsuccessful"

git pull -q origin $git_branch

#if the release branch already exist overwrite, else create
op_message=`git branch $release_branch 2>&1`

if [ $? != 0 ]; then

                chk_branch_exist=$(echo "$op_message" | grep 'already exists')


                if [ -n "$chk_branch_exist" ]
                then
                        git checkout $release_branch
                        fn_chkstatus $? "Git checkout branch - $release_branch unsuccessful '$chk_branch_exist'"
                else
                        fn_chkstatus 1 "Git create branch - $release_branch unsuccessful"
                fi
else
        git checkout $release_branch
        fn_chkstatus $? "Git checkout - $release_branch unsuccessful"

        rm -rf *
        fn_chkstatus $? "Git remove files in  release branch - $release_branch unsuccessful"
fi

#Loop through the export list and return error message if any
while read line
do

        exptype=`echo $line | cut -d ',' -f1`
        export_object_type=$(fn_uppercase $exptype)

        objname=`echo $line | cut -d ',' -f2`
        export_object_name=$(fn_lowercase $objname)

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

#Check export_object_type is onscope
if [[ ! "$export_object_type" =~ ^(PROJECT|LAYER|JOBFLOW|DATAFLOW|DOBJ|DATAPOINT)$ ]];
then
        echo "Only below object can be exported:"
        echo "          project   - to export entire project"
        echo "          layer     - to export entire layer"
        echo "          jobflow   - to export jobflow"
        echo "          dataflow  - to export dataflow"
        echo "          dobj      - to export dobj"
        echo "          datapoint - to export datapoint"
        exit 1
fi

#Check object_type is onscope
if [[ "$export_object_type" =~ ^(DOBJ|DATAPOINT)$ ]];
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

if [ "$export_object_type" == "PROJECT" ]
then
        prj_dir=$(fn_uppercase $export_object_name)
        filename="${tgt_diyotta_loc}/${prj_dir}/project/${export_object_name}.json"

        #call function to create directory if not exist
        fn_createdir ${tgt_diyotta_loc}/${prj_dir}/project

        if [[ -z $export_object_name ]];
        then
                fn_missingargs $export_object_type "To Export PROJECT - Export_Object_Name is Mandatory"
        fi

        echo "dicmd export -p $prj_dir -f $filename" >> $tmp_home/tmp_export_dicmd.lst

elif [ "$export_object_type" == "LAYER" ]
then
        filename="${tgt_diyotta_loc}/${project_name}/layer/${export_object_name}.json"

        #call function to create directory if not exist
        fn_createdir ${tgt_diyotta_loc}/${project_name}/layer

        if [[ -z $project_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type "To Export LAYER - Export_Object_Name and Project are Mandatory details"
        fi

        echo "dicmd export -p $project_name -l $export_object_name -f $filename" >> $tmp_home/tmp_export_dicmd.lst


elif [ "$export_object_type" == "JOBFLOW" ]
then
        filename="${tgt_diyotta_loc}/${project_name}/jobflow/${layer_name}/${export_object_name}.json"

        #call function to create directory if not exist
        fn_createdir ${tgt_diyotta_loc}/${project_name}/jobflow/${layer_name}

        if [[ -z $project_name || -z $layer_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type "To Export JOBFLOW - Export_Object_Name,Project and layer are Mandatory details"
        fi

        echo "dicmd export -p $project_name -l $layer -o $export_object_type -n $export_object_name -f $filename" >> $tmp_home/tmp_export_dicmd.lst

elif [ "$export_object_type" == "DATAFLOW" ]
then
        filename="${tgt_diyotta_loc}/${project_name}/dataflow/${layer_name}/${export_object_name}.json"

        #call function to create directory if not exist
        fn_createdir ${tgt_diyotta_loc}/${project_name}/dataflow/${layer_name}

        if [[ -z $project_name || -z $layer_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type "To Export DATAFLOW - Export_Object_Name,Project and layer are Mandatory details"
        fi

        echo "dicmd export -p $project_name -l $layer -o $export_object_type -n $export_object_name -f $filename" >> $tmp_home/tmp_export_dicmd.lst

elif [ "$export_object_type" == "DOBJ" ]
then
        filename="${tgt_diyotta_loc}/${project_name}/dataobject/${group_name}/${data_point}_${group_name}_${export_object_name}.json"

        #call function to create directory if not exist
        fn_createdir ${tgt_diyotta_loc}/${project_name}/dataobject/${group_name}

        if [[ -z $project_name || -z $object_type || -z $data_point || -z $group_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type "To Export DOBJ - Export_Object_Name,project,Datapoint,Group and Object_type are Mandatory details"
        fi

        echo "dicmd export -p $project_name -o $export_object_type -t $object_type -g $group_name -c $data_point -n $export_object_name -f $filename" >> $tmp_home/tmp_export_dicmd.lst

elif [ "$export_object_type" == "DATAPOINT" ]
then
        obj_type=$(fn_lowercase $object_type)
        filename="${tgt_diyotta_loc}/${project_name}/datapoint/${group_name}/${obj_type}_${group_name}_${export_object_name}.json"

        #call function to create directory if not exist
        fn_createdir ${tgt_diyotta_loc}/${project_name}/datapoint/${group_name}

        if [[ -z $project_name || -z $object_type || -z $group_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type "To Export DATAPOINT - Export_Object_Name,project,Group and Object_type are Mandatory details"
        fi

        echo "dicmd export -p $project_name -o $export_object_type -t $object_type -g $group_name -n $export_object_name -f $filename" >> $tmp_home/tmp_export_dicmd.lst

else
        echo "Invalid export_object_type"
fi


done < "/home/di/diyotta/controller/support/tmp/export.lst"


#Loop through all the dicmd export command generated and export the object
while read -r line
do
                filename=`echo $line | rev | cut -d'/' -f1 | rev`
        echo "Exporting: $filename "
        op_message=`$line 2>&1`

                                if [ $? != 0 ]; then
                        echo -e "Export $filename- unsuccessful \n \t $op_message"
                        exit 1
                else
                        echo "Export $filename - Successfully completed"
                fi
done < $tmp_home/tmp_export_dicmd.lst

#Commiting all the changes in release branch
git add *
git commit -a -q -m "$commit_msg"

#Pushing all the committed files to the remote repository
echo "Pushing the $release_branch to the remote repository"
git push -u origin $release_branch
fn_chkstatus $? "Git push release branch to remote repository- $release_branch unsuccessful"

echo "$release_branch created with exported files"

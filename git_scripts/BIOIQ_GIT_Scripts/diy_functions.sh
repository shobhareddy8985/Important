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

#convert string to uppercase
fn_uppercase()
{
        opvar=`echo "$1" | tr '[:lower:]' '[:upper:]'`
        echo $opvar

}

#convert string to lowercase
fn_lowercase()
{
        opvar=`echo "$1" | tr '[:upper:]' '[:lower:]'`
        echo $opvar

}

#remove file if it exist
fn_rmfile()
{
                filename=$1
                if [ -f $filename ] ; then
                        rm -r $filename
                fi
}

#Function will create directory if not exist
fn_createdir()
{
                path=$1
                if [ ! -d $path ]
                then
                        mkdir -p $path
                fi
}

#Return error message if required arguments missing
fn_missingargs()
{
        ipstr=$1
		err_msg=$2

        echo "$err_msg"
        exit 1
}

#Return error message and exit if the arguments passed not equal to 0
fn_chkstatus()
{
        prev_status=$1
        message=$2

        if [ $prev_status != 0 ]; then
                        echo "ERROR - $2"
                        exit 1
        fi

}

#add and commit files to the git remote repository
fn_gitcommit()
{
       git_file=$1
	   commit_msg=$2
       
	   git add $git_file
       git commit -m "$commit_msg" $git_file

}

#Function will create directory if not exist
fn_checkdir()
{
                path=$1
                if [ ! -d $path ]
                then
                        echo "$path - directory not exist"
                fi
}

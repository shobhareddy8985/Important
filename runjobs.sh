
#!/bin/bash
##################################################################
# Copyright (c) Diyotta Inc. All rights reserved.                #
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.  #
#                                                                #
# This source file is proprietary property of Diyotta, Inc.      #
# This code is cannot be copied and/or redistributed and/or      #
# modified without prior permission from  Diyotta.               #
# Please contact us at contact@diyotta.com or                    #
# visit www.diyotta.com if you need additional information.      #
##################################################################


if [ "V${DI_HOME}V" != "VV" ];
then
DI_FLA_HOME=$DI_HOME
export DI_FLA_HOME=$DI_FLA_HOME
fi


# Check environment variable
chkenv () {
        val=$DI_FLA_HOME
        #echo ${val}
        if [ "V${val}V" == "VV" ];
        then
                echo "ERROR:Undefined Environment Variable: DI_HOME/DI_FLA_HOME(at least one should be set)"
                exit 1
        fi
}

# CHECKING  ENVIRONEMNT VARIABLE VALUES
chkenv ;
export DI_HOME=${DI_FLA_HOME}
export JAVA_HOME=${DI_FLA_HOME}/server/jre
export PATH=${DI_FLA_HOME}/server/jre/bin:$PATH
export PATH


export CLASSPATH="${DI_HOME}/support/lib/*"


java com.diyotta.impl.RunJobs "$@"

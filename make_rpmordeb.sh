#!/bin/bash

SHELL_PATH=$(cd "$(dirname "$0")";pwd)
echo "SHELL_PATH={SHELL_PATH}"
echo ${PKG_TYPE}
echo ${BUILD_NUMBER}

BVersion=$Version
ABPLATFORM=`echo $NODE_LABELS | cut -d ' ' -f 1`
AB_URL=ftp://192.168.123.46/ci-jobs/AB${BVersion}/package/AnyBackupClient/$ABPLATFORM/${JOB_NAME}-latest.tar.gz
HW_URL=ftp://192.168.123.46/ci-jobs/AB${BVersion}/package/HuaweiClient/$ABPLATFORM/${JOB_NAME}-latest.tar.gz
OS_Type=`uname -p`
RPMBUILD_PATH=/root/rpmbuild
DEBBUILD_PATH=/root/debbuild
SPECS_NAME=anybackup

if [ "$PKG_TYPE" = "huaweirpm" ];
then
    SPECS_NAME=huawei
fi

if [ "$ABPLATFORM" = "Redhat_5_x64" ];
then
    RPMBUILD_PATH=/usr/src/redhat
else
    RPMBUILD_PATH=/root/rpmbuild
fi

if [ -n "$(echo ${PKG_TYPE}|grep rpm)" ]; then
    /bin/rm -rf $RPMBUILD_PATH/*
    mkdir -p $RPMBUILD_PATH/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

    /bin/cp -rf $SHELL_PATH/$SPECS_NAME-client-7.spec $RPMBUILD_PATH/SPECS
    eval sed -i 's/666/${BUILD_NUMBER}/g' $RPMBUILD_PATH/SPECS/$SPECS_NAME-client-7.spec
    eval sed -i 's/test-wzs/${BVersion}/g' $RPMBUILD_PATH/SPECS/$SPECS_NAME-client-7.spec
else
    /bin/rm -rf $DEBBUILD_PATH/*
    mkdir -p $DEBBUILD_PATH/DEBIAN

    /bin/cp -rf $SHELL_PATH/deb_config/* $DEBBUILD_PATH/DEBIAN
	eval sed -i 's/7.0.7/${BVersion}/g' $DEBBUILD_PATH/DEBIAN/control

	if [ -n "$(echo ${PKG_TYPE}|grep huawei)" ]; then
        #eval sed -i 's/666/${BUILD_NUMBER}/g' $RPMBUILD_PATH/SPECS/$SPECS_NAME-client-7.spec
        sed -i 's/AnyBackupClient/HuaweiClient/g' $DEBBUILD_PATH/DEBIAN/control
	fi

fi

cd ${SHELL_PATH}
if [ "$PKG_TYPE" = "rpm" ];
then
    if [ "$ABPLATFORM" = "Redhat_5_x64" ];
    then
        #cd /opt
        #wget ${AB_URL}
        #tar -zxf ${JOB_NAME}-latest.tar.gz
        #rm -rf ${JOB_NAME}-latest.tar.gz
        #sed -i '/cp -a/d' $RPMBUILD_PATH/SPECS/anybackup-client-7.spec
        #sed -i '/install -d/d' $RPMBUILD_PATH/SPECS/anybackup-client-7.spec
        sed -i '/lib/d' $RPMBUILD_PATH/SPECS/anybackup-client-7.spec
        for((i=1;i<24;i++)); do sed -i '$d' $RPMBUILD_PATH/SPECS/anybackup-client-7.spec; done

        rm -rf $RPMBUILD_PATH/BUILD/*
        mkdir -p $RPMBUILD_PATH/BUILD/opt
        mkdir -p $RPMBUILD_PATH/BUILD/var/lib/AnyBackup/config
        mkdir -p $RPMBUILD_PATH/BUILD/var/log/AnyBackup

        cd $RPMBUILD_PATH/BUILD/opt/

        wget ${AB_URL}

        tar -zxf ${JOB_NAME}-latest.tar.gz

        rm -rf ${JOB_NAME}-latest.tar.gz
        
        cp -rf $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/cfl.conf $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/zh_cfl.config 
        mv  $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/ClientService $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/ABClientService
        chmod 755 $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/ABClientService
        cp -rf $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/ABClientService $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/ABClientService.origin

        mkdir $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/{orascript,temp,user}
        chmod 777 $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/{orascript,temp,user}

    else
        rm -rf $RPMBUILD_PATH/BUILD/*
        mkdir -p $RPMBUILD_PATH/BUILD/opt
        mkdir -p $RPMBUILD_PATH/BUILD/lib/systemd/system
        mkdir -p $RPMBUILD_PATH/BUILD/var/lib/AnyBackup/config
        mkdir -p $RPMBUILD_PATH/BUILD/var/log/AnyBackup

        cd $RPMBUILD_PATH/BUILD/opt/

        wget ${AB_URL}

        tar -zxf ${JOB_NAME}-latest.tar.gz

        rm -rf ${JOB_NAME}-latest.tar.gz
        
        cp -rf $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/cfl.conf $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/zh_cfl.config 
        cp -rf $SHELL_PATH/rpm_deb_replace/ABClientService.service $RPMBUILD_PATH/BUILD/lib/systemd/system/
        rm -rf $RPMBUILD_PATH/BUILD/opt/ClientService.service
        cp -rf $SHELL_PATH/rpm_deb_replace/ABClientService.service $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/
        cp -rf $SHELL_PATH/rpm_deb_replace/ABClientService.service.origin $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/
        cp -rf $SHELL_PATH/rpm_deb_replace/abenv $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/

        mkdir $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/{orascript,temp,user}
        chmod 777 $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/{orascript,temp,user}

    fi

    rpmbuild -bb $RPMBUILD_PATH/SPECS/anybackup-client-7.spec

    mkdir -p /var/JFR_apollo_branch/workspace/RpmPKG/label/$ABPLATFORM/package/$ABPLATFORM
    
    mv $RPMBUILD_PATH/RPMS/$OS_Type/AnyBackupClient-${BVersion}-${BUILD_NUMBER}.$OS_Type.rpm $RPMBUILD_PATH/RPMS/$OS_Type/AnyBackupClient-${BVersion}-${BUILD_NUMBER}-${ABPLATFORM}.$OS_Type.rpm

    mv $RPMBUILD_PATH/RPMS/$OS_Type/AnyBackupClient-${BVersion}-${BUILD_NUMBER}-${ABPLATFORM}.$OS_Type.rpm /var/JFR_apollo_branch/workspace/RpmPKG/label/$ABPLATFORM/package/$ABPLATFORM

    rm -rf $RPMBUILD_PATH/RPMS/$ABPLATFORM/*
    
    #if [ "$ABPLATFORM" = "Redhat_5_x64" ];
    #then
    #rm -rf /opt/AnyBackupClient
    #fi
elif [ "$PKG_TYPE" = "huaweirpm" ];then
    if [ "$ABPLATFORM" = "Redhat_5_x64" ];
    then
        #cd /opt
        #wget ${HW_URL}
        #tar -zxf ${JOB_NAME}-latest.tar.gz
        #rm -rf ${JOB_NAME}-latest.tar.gz
        #sed -i '/cp -a/d' $RPMBUILD_PATH/SPECS/huawei-client-7.spec
        #sed -i '/install -d/d' $RPMBUILD_PATH/SPECS/huawei-client-7.spec
        sed -i '/lib/d' $RPMBUILD_PATH/SPECS/huawei-client-7.spec
        for((i=1;i<24;i++)); do sed -i '$d' $RPMBUILD_PATH/SPECS/huawei-client-7.spec; done

        rm -rf $RPMBUILD_PATH/BUILD/*
        mkdir -p $RPMBUILD_PATH/BUILD/opt
        mkdir -p $RPMBUILD_PATH/BUILD/var/CDM/AnyBackup/config
        mkdir -p $RPMBUILD_PATH/BUILD/var/CDM/AnyBackup

        cd $RPMBUILD_PATH/BUILD/opt/

        wget ${AB_URL}

        tar -zxf ${JOB_NAME}-latest.tar.gz

        rm -rf ${JOB_NAME}-latest.tar.gz
        
        cp -rf $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/cfl.conf $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/zh_cfl.config 
        mv  $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/ClientService $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/HWClientService
        chmod 755 $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/HWClientService
        cp -rf $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/HWClientService $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/HWClientService.origin

        mkdir $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/{orascript,temp,user}
        chmod 777 $RPMBUILD_PATH/BUILD/opt/AnyBackupClient/ClientService/{orascript,temp,user}

    else
        rm -rf $RPMBUILD_PATH/BUILD/*
        mkdir -p $RPMBUILD_PATH/BUILD/opt
        mkdir -p $RPMBUILD_PATH/BUILD/lib/systemd/system
        mkdir -p $RPMBUILD_PATH/BUILD/var/CDM/AnyBackup/config
        mkdir -p $RPMBUILD_PATH/BUILD/var/CDM/AnyBackup

        cd $RPMBUILD_PATH/BUILD/opt/

        wget ${AB_URL}

        tar -zxf ${JOB_NAME}-latest.tar.gz

        rm -rf ${JOB_NAME}-latest.tar.gz
        
        cp -rf $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/cfl.conf $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/zh_cfl.config 
        cp -rf $SHELL_PATH/rpm_deb_replace/HWClientService.service $RPMBUILD_PATH/BUILD/lib/systemd/system/
        rm -rf $RPMBUILD_PATH/BUILD/opt/ClientService.service
        cp -rf $SHELL_PATH/rpm_deb_replace/HWClientService.service $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/
        sed -i 's#AnyBackupClient/ClientService#HuaweiClient/HWClientService#g' $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/HWClientService.service
        cp -rf $SHELL_PATH/rpm_deb_replace/ABClientService.service.origin $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/HWClientService.service.origin
        cp -rf $SHELL_PATH/rpm_deb_replace/abenv $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/
        sed -i 's#AnyBackupClient/ClientService#HuaweiClient/HWClientService#g' $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/abenv

        mkdir $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/{orascript,temp,user}
        chmod 777 $RPMBUILD_PATH/BUILD/opt/HuaweiClient/HWClientService/{orascript,temp,user}
    fi

    rpmbuild -bb $RPMBUILD_PATH/SPECS/huawei-client-7.spec

    mkdir -p /var/JFR_apollo_branch/workspace/RpmPKG/label/$ABPLATFORM/package/$ABPLATFORM

    mv $RPMBUILD_PATH/RPMS/$OS_Type/HuaweiClient-${BVersion}-${BUILD_NUMBER}.$OS_Type.rpm $RPMBUILD_PATH/RPMS/$OS_Type/HuaweiClient-${BVersion}-${BUILD_NUMBER}-${ABPLATFORM}.$OS_Type.rpm
    
    mv $RPMBUILD_PATH/RPMS/$OS_Type/HuaweiClient-${BVersion}-${BUILD_NUMBER}-${ABPLATFORM}.$OS_Type.rpm /var/JFR_apollo_branch/workspace/RpmPKG/label/$ABPLATFORM/package/$ABPLATFORM

    rm -rf $RPMBUILD_PATH/RPMS/$ABPLATFORM/*
elif [ "$PKG_TYPE" = "deb" ];then
    rm -rf $DEBBUILD_PATH/DEBIAN/*
    mkdir -p $DEBBUILD_PATH/opt
    mkdir -p $DEBBUILD_PATH/BUILD/lib/systemd/system
    
    cd $DEBBUILD_PATH/DEBIAN/opt/

    wget ${AB_URL}

    tar -zxf ${JOB_NAME}-latest.tar.gz

    rm -rf ${JOB_NAME}-latest.tar.gz
        
    cp -rf $DEBBUILD_PATH/opt/AnyBackupClient/ClientService/cfl.conf $DEBBUILD_PATH/opt/AnyBackupClient/ClientService/zh_cfl.config 
    cp -rf $SHELL_PATH/rpm_deb_replace/ABClientService.service $DEBBUILD_PATH/lib/systemd/system/
    rm -rf $DEBBUILD_PATH/opt/ClientService.service
    cp -rf $SHELL_PATH/rpm_deb_replace/ABClientService.service $DEBBUILD_PATH/opt/AnyBackupClient/ClientService/
    cp -rf $SHELL_PATH/rpm_deb_replace/ABClientService.service.origin $DEBBUILD_PATH/opt/AnyBackupClient/ClientService/
    cp -rf $SHELL_PATH/rpm_deb_replace/abenv $DEBBUILD_PATH/opt/AnyBackupClient/ClientService/

    mkdir $DEBBUILD_PATH/opt/AnyBackupClient/ClientService/{orascript,temp,user}
    chmod 777 $DEBBUILD_PATH/opt/AnyBackupClient/ClientService/{orascript,temp,user}


    mkdir -p /var/JFR_apollo_branch/workspace/DebPKG/label/$ABPLATFORM/package/$ABPLATFORM

    dpkg-deb -b $DEBBUILD_PATH /var/JFR_apollo_branch/workspace/DebPKG/label/$ABPLATFORM/package/$ABPLATFORM/AnyBackupClient-${BVersion}-${BUILD_NUMBER}-${ABPLATFORM}.$OS_Type.deb
    
elif [ "$PKG_TYPE" = "huaweirpm" ];then
    rm -rf $DEBBUILD_PATH/DEBIAN/*
    mkdir -p $DEBBUILD_PATH/opt
    mkdir -p $DEBBUILD_PATH/BUILD/lib/systemd/system
    
    cd $DEBBUILD_PATH/DEBIAN/opt/

    wget ${AB_URL}

    tar -zxf ${JOB_NAME}-latest.tar.gz

    rm -rf ${JOB_NAME}-latest.tar.gz
        
    cp -rf $DEBBUILD_PATH/DEBIAN/opt/HuaweiClient/HWClientService/cfl.conf $DEBBUILD_PATH/opt/HuaweiClient/HWClientService/zh_cfl.config 
    cp -rf $SHELL_PATH/rpm_deb_replace/HWClientService.service $DEBBUILD_PATH/lib/systemd/system/
    rm -rf $DEBBUILD_PATH/opt/ClientService.service
    cp -rf $SHELL_PATH/rpm_deb_replace/HWClientService.service $DEBBUILD_PATH/opt/HuaweiClient/HWClientService/
    sed -i 's#AnyBackupClient/ClientService#HuaweiClient/HWClientService#g' $DEBBUILD_PATH/opt/HuaweiClient/HWClientService/HWClientService.service
    cp -rf $SHELL_PATH/rpm_deb_replace/ABClientService.service.origin $DEBBUILD_PATH/opt/HuaweiClient/HWClientService/HWClientService.service.origin
    cp -rf $SHELL_PATH/rpm_deb_replace/abenv $DEBBUILD_PATH/opt/HuaweiClient/HWClientService/
    sed -i 's#AnyBackupClient/ClientService#HuaweiClient/HWClientService#g' $DEBBUILD_PATH/opt/HuaweiClient/HWClientService/abenv

    mkdir $DEBBUILD_PATH/opt/HuaweiClient/HWClientService/{orascript,temp,user}
    chmod 777 $DEBBUILD_PATH/opt/HuaweiClient/HWClientService/{orascript,temp,user}


    mkdir -p /var/JFR_apollo_branch/workspace/DebPKG/label/$ABPLATFORM/package/$ABPLATFORM

    dpkg-deb -b $DEBBUILD_PATH /var/JFR_apollo_branch/workspace/DebPKG/label/$ABPLATFORM/package/$ABPLATFORM/HuaweiClient-${BVersion}-${BUILD_NUMBER}-${ABPLATFORM}.$OS_Type.deb

else
    echo "wrong!!"
    exit 0
fi


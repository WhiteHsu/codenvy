#!/bin/bash

# bash <(curl -s https://codenvy.com/update/repository/public/download/install-script)

CODENVY_USER=codenvy
CODENVY_HOME=/home/${CODENVY_USER}
APP_DIR=${CODENVY_HOME}/installation-manager
SCRIPT_NAME=installation-manager
SERVICE_NAME=codenvy-${SCRIPT_NAME}

# $1 - username; $2 - uid/gid
useraddDebian() {
    sudo adduser --quiet --shell /bin/bash --uid $2 --gid $2 --disabled-password --gecos "" $1
    sudo passwd -q -d -l $1
}

# $1 - username; $2 - uid/gid
useraddRedhat() {
    sudo useradd --create-home --shell /bin/bash --uid $2 --gid $2 $1
    sudo passwd -l $1
}

# $1 - username; $2 - uid/gid
useraddOpensuse() {
    sudo -s useradd --create-home --shell /bin/bash --uid $2 --gid $2 $1
    sudo -s passwd -q -l $1
}

# $1 - groupname; $2 - gid (optional)
groupaddDebian() {
    if [ -z  "$2" ]; then
        sudo addgroup $1
    else
        sudo addgroup --quiet --gid $2 $1
    fi
}

# $1 - groupname; $2 - gid (optional)
groupaddRedhat() {
    if [ -z  "$2" ]; then
        sudo groupadd $1
    else
        sudo groupadd -g$2 $1
    fi
}

# $1 - groupname; $2 - gid (optional)
groupaddOpensuse() {
    if [ -z  "$2" ]; then
        sudo -s groupadd $1
    else
        sudo -s groupadd -g$2 $1
    fi
}

createCodenvyUserAndGroup() {
    if [ `grep -c "^${CODENVY_USER}" /etc/group` == 0 ]; then
        echo "> Creating group codenvy"
        groupadd${os} ${CODENVY_USER} 5001
    fi

    if [ `grep -c "^${CODENVY_USER}:" /etc/passwd` == 0 ]; then
        echo "> Creating user codenvy"
        useradd${os} ${CODENVY_USER} 5001
    fi
}

installJava() {
    command -v java >/dev/null 2>&1 || {     # check if requered program had already installed earlier
        echo "> Installation manager requires java to be installed "
        read -p "> Press any key to start downloading java" -n1 -s
        wget --no-cookies --no-check-certificate --header 'Cookie: oraclelicense=accept-securebackup-cookie' 'http://download.oracle.com/otn-pub/java/jdk/7u17-b02/jdk-7u17-linux-x64.tar.gz' --output-document=jdk.tar.gz

        echo "> Unpacking JDK binaries to /usr/local "
        sudo tar -xf jdk.tar.gz -C /usr/local

        sudo su - ${CODENVY_USER} -c "sed -i '1i\export JAVA_HOME=/usr/local/jdk1.7.0_17' ~/.bashrc"
        sudo su - ${CODENVY_USER} -c "sed -i '2i\export PATH=$PATH:/usr/local/jdk1.7.0_17/bin' ~/.bashrc"

        sed -i '1i\export JAVA_HOME=/usr/local/jdk1.7.0_17' ~/.bashrc
        sed -i '2i\export PATH=$PATH:/usr/local/jdk1.7.0_17/bin' ~/.bashrc

        rm jdk.tar.gz
        echo "> Java has been installed"
    }
}

registerIMServiceDebian() {
    # http://askubuntu.com/questions/99232/how-to-make-a-jar-file-run-on-startup-and-when-you-log-out
    echo "> Register Codenvy Installation Manage Service"
    sudo update-rc.d ${SERVICE_NAME} defaults &>/dev/null
}

registerIMServiceRedhat() {
    # http://www.abhigupta.com/2010/06/how-to-auto-start-services-on-boot-in-redhat-redhat/
    echo "> Registering Codenvy Installation Manage Service"
    sudo chkconfig --add ${SERVICE_NAME} &>/dev/null
    sudo chkconfig ${SERVICE_NAME} on &>/dev/null
}

registerIMServiceOpensuse() {
    # http://www.abhigupta.com/2010/06/how-to-auto-start-services-on-boot-in-redhat-redhat/
    echo "> Registering Codenvy Installation Manage Service"
    sudo -s chkconfig --add ${SERVICE_NAME} &>/dev/null
    sudo -s chkconfig ${SERVICE_NAME} on &>/dev/null
}

# $1 - command name
installOnDebian() {
    sudo apt-get install $1 -y
}

# $1 - command name
installOnRedhat() {
    sudo yum install $1 -y
}

# $1 - command name
installOnOpensuse() {
    sudo -s zypper install $1 -y
}

# $1 - command name
installCommand() {
    command -v $1 >/dev/null 2>&1 || {     # check if requered command had already installed earlier
        echo "> Installation $1 "
        installOn${os} $1
        echo "> $1 has been installed"
    }
}

installIM() {
    echo "> Downloading Installation Manager "

    DOWNLOAD_URL="https://codenvy.com/update/repository/public/download/installation-manager"

    filename=$(curl -sI  ${DOWNLOAD_URL} | grep -o -E 'filename=(.*)[.]tar.gz' | sed -e 's/filename=//')
    curl -o ${filename} -L ${DOWNLOAD_URL}

    # removes existed files and creates new directory
    sudo rm ${APP_DIR} -rf
    sudo mkdir ${APP_DIR}

    # untar archive
    sudo tar -xf ${filename} -C /tmp
    sudo tar -xf /tmp/${filename} -C ${APP_DIR}

    # create symbol link to installation-manager script into /etc/init.d
    sudo ln -s ${APP_DIR}/${SCRIPT_NAME} /etc/init.d/${SERVICE_NAME}

    # make it possible to write files into the APP_DIR
    sudo chmod 757 ${APP_DIR}

    # make the user ${CODENVY_USER} an owner all files into the APP_DIR
    sudo chown -R ${CODENVY_USER}:${CODENVY_USER} ${APP_DIR}


    DOWNLOAD_URL="https://codenvy.com/update/repository/public/download/installation-manager-cli"
    filename=$(curl -sI  ${DOWNLOAD_URL} | grep -o -E 'filename=(.*)[.]tar.gz' | sed -e 's/filename=//')

    # removes existed files and creates new directory
    cliinstalled=${HOME}/im-cli
    rm ${cliinstalled} -rf &>/dev/null
    mkdir ${cliinstalled}

    tar -xf /tmp/${filename} -C ${cliinstalled}

    # create shared directory between 'codenvy' and current user
    cliupdatedir=/home/codenvyshared
    CODENVY_SHARE_GROUP=codenvyshare
    USER_GROUP=$(groups | cut -d ' ' -f1)
    sudo mkdir ${cliupdatedir}
    groupadd${os} ${CODENVY_SHARE_GROUP}
    sudo chown -R root.${CODENVY_SHARE_GROUP} ${cliupdatedir}
    sudo gpasswd -a ${CODENVY_USER} ${CODENVY_SHARE_GROUP}
    sudo gpasswd -a ${USER} ${CODENVY_SHARE_GROUP}
    sudo chmod ug+rwx -R ${cliupdatedir}
    sudo chmod g+s ${cliupdatedir}
    sudo su - ${CODENVY_USER} -c "sed -i '1i\umask 002' ~/.bashrc"

    # store parameters of installed Installation Manager CLI.
    sudo su -c "mkdir ${CODENVY_HOME}/.codenvy"
    sudo su -c "echo -e '${cliinstalled}\n${cliupdatedir}\n${CODENVY_SHARE_GROUP}\n${USER}\n${USER_GROUP}' > ${CODENVY_HOME}/.codenvy/im-cli-installed"
    sudo su -c "chown -R ${CODENVY_USER}:${CODENVY_USER} ${CODENVY_HOME}/.codenvy"
}

launchingIMService() {
    echo "> Launching Codenvy Installation Manage Service"
    # try to stop exists installation-manager
    sudo /etc/init.d/${SERVICE_NAME} stop
    sudo kill -9 $(ps aux | grep [i]nstallation-manager | cut -d" " -f4) &>/dev/null  # kill manager if stop isn't work

    # launch new installation-manager
    sudo /etc/init.d/${SERVICE_NAME} start
}

if [ -f /etc/debian_version ]; then
    os="Debian"
elif [ -f /etc/redhat-release ]; then
    os="Redhat"
elif [ -f /etc/os-release ]; then
    os="Opensuse"
else
    echo "> Operation system isn't supported."
    exit
fi

echo "> System is run on ${os} based distributive."

createCodenvyUserAndGroup

installCommand curl
installCommand tar
installCommand wget
installJava
installIM

registerIMService${os}
launchingIMService



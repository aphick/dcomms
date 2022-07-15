#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

set -e
# Directory to save dcomms config files in
DCOMMS_DIR=

COMPOSE_FILES="-f ./conf/compose/docker-compose.yml "

# Docker saved file names
DOCKER_FILES=("caddy_2.5.1.tar")
D_IMAGES=("caddy:2.5.1")
FILE_MAGNETS=("${MAGNET_LINKS[0]}$MAG_TRACKERS")

CONF_FILE="dcomms-conf_v1.tar"

DCOMMS_INSTANCES=(
    "kyiv.dcomm.net.ua"
    "odessa.dcomm.net.ua"
    "kharkiv.dcomm.net.ua"
    "lviv.dcomm.net.ua"
    "lviv2.dcomm.net.ua"
    "rivne.dcomm.net.ua"
    "kherson.dcomm.net.ua"
    "mykolayiv.dcomm.net.ua"
)

IPFS_GATEWAYS=(
    "cf-ipfs.com/ipfs"
    "gateway.ipfs.io/ipfs"
    "cloudflare-ipfs.com/ipfs/"
    "ipfs.io/ipfs"
    "ipfs.best-practice.se/ipfs"
    "ipfs.2read.net/ipfs"
)

IPFS_DIR="QmdnJmd6QPTjbLbo8bet5RwgMJZH4bbVvZ1XVJngLfJw4L"

#List of trackers for generating the magnet link, only use this once to save on space
MAG_TRACKERS="&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2F9.rarbg.com%3A2810%2Fannounce&tr=udp%3A%2F%2Fopen.tracker.cl%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=http%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Fopentracker.i2p.rocks%3A6969%2Fannounce&tr=https%3A%2F%2Fopentracker.i2p.rocks%3A443%2Fannounce&tr=udp%3A%2F%2Fwww.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce&tr=udp%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.dler.org%3A6969%2Fannounce&tr=udp%3A%2F%2Ftr.cili001.com%3A8070%2Fannounce&tr=udp%3A%2F%2Fipv4.tracker.harry.lu%3A80%2Fannounce&tr=udp%3A%2F%2Fexplodie.org%3A6969%2Fannounce&tr=udp%3A%2F%2Fbt.oiyo.tk%3A6969%2Fannounce&tr=https%3A%2F%2Ftracker.nanoha.org%3A443%2Fannounce&tr=https%3A%2F%2Ftracker.logirl.moe%3A443%2Fannounce&tr=https%3A%2F%2Ftracker.lilithraws.org%3A443%2Fannounce"

#Big ugly blob of links. Yikes
MAGNET_LINKS=(
    "magnet:?xt=urn:btih:BCADB433F6B22E040137482728110A8573EA6550&dn=caddy_2.5.1.tar"
    "magnet:?xt=urn:btih:3049C0A1E9EA85C229ABC1E252100F6F75C62AE9&dn=ceno-client_v0.21.1.tar"
    "magnet:?xt=urn:btih:DC06F639170378BB09F8B762A9C6F1D813599195&dn=deltachat-mailadm-dovecot_v0.0.1.tar"
    "magnet:?xt=urn:btih:F1CC8614114FA87FEA8AE47FB1C572DCD8AFC1B0&dn=deltachat-mailadm-postfix_v0.0.3.tar"
    "magnet:?xt=urn:btih:CFED08F4ACD38AE7B741970418B5B76B459E3B0B&dn=deltachat-mailadm_v0.0.1.tar"
    "magnet:?xt=urn:btih:3AE1FCB573DE6D6B66A82C651F6F39449D2E8BB1&dn=element-web_v1.10.14.tar"
    "magnet:?xt=urn:btih:FDB9A84967278CB506C637E482297672C567BB43&dn=mastodon-sendmail_0.2.tar"
    "magnet:?xt=urn:btih:4F6522CED130784EBD0846F2B4A56C10A3D02641&dn=maubot_v0.3.1.tar"
    "magnet:?xt=urn:btih:E278B8C1386477E8728C77AC3478D60ECE20E0AE&dn=postgres_14-alpine.tar"
    "magnet:?xt=urn:btih:EB9DC0FC067DFC1DEC9208EA3C4232E57AB43344&dn=redis_6.0-alpine.tar"
    "magnet:?xt=urn:btih:B44D1CADF49884521403C2E50F7487D7355BADBC&dn=synapse_v1.60.0.tar"
)

CONF_MAGNET="magnet:?xt=urn:btih:C4A2659BC8B2A10924F017970F35815DE90B0283&dn=dcomms-conf_v1.tar$MAG_TRACKERS"
#CONF_MAGNET="$MAG_TRACKERS"

export HUB_REACHABLE=false
export DCOMM_REACHABLE=false
export IPFS_REACHABLE=false
export TOR_AVAIL=false
i=0

echo "This script requires root access to interact with Docker. Please enter your password if prompted."
sudo echo ""

#This funciton uses which to discover what packages are installed on this system.
#Should investigate which command has the most interoperability
check_requirements () {
    if ! which curl docker >/dev/null; then
        printf "${RED}## This script depends on curl and docker.\n"
        printf "Please install 'curl' and/or install docker.\n"
        printf "https://docs.docker.com/engine/install/${NC}\n"
        exit 1
    fi
    if ! which aria2c>/dev/null; then
        printf "${YELLOW}## This script requires aria2 to download torrents in "
        printf "the event that Docker Hub or the Dcomms servers are unreachable.\n"
        printf "If you require this functionality please install 'aria2'${NC}\n"
        TORRENT_AVAIL=false
        ((i=i+=1))
    else
        TORRENT_AVAIL=true
    fi
    if which tor >/dev/null; then
        TOR_AVAIL=true
    else
        printf "${YELLOW}## This script can take advantage of Tor to route around "
        printf "blockages and allow users to connect anonymously to your server.\n"
        printf "If you would like this functionality enabled please install 'tor'${NC}\n"
    fi
}

detect_connectivity () {
    # This function tests all available means to retrieve the Dcomms repository.
    if sudo docker pull hello-world >/dev/null 2>&1; then
        sudo docker rmi hello-world >/dev/null 2>&1
        printf "${GREEN}## Successfully connected to Docker Hub${NC}\n"
        HUB_REACHABLE=true
    else
        printf "${RED}## Unable to connect to Docker Hub${NC}\n"
        ((i=i+=1))
    fi

    for site in ${DCOMMS_INSTANCES[@]}; do
        #this function should be more complex
        if curl -s -m 3 https://$site/dcomms -o /tmp/dcomms; then
            if (( $(stat -c %s /tmp/dcomms) > 3 )); then
                DCOMM_URL=https://$site/dcomms
                printf "${GREEN}## Successfully connected to $site${NC}\n"
                DCOMM_REACHABLE=true
                rm /tmp/dcomms
                break
            fi
            rm /tmp/dcomms
        fi
    done

    if [[ "${DCOMM_REACHABLE}" == false ]]; then
        printf "${RED}## Unable to connect to Dcomms instance${NC}\n"
        ((i=i+=1))
    fi

#    for site in ${IPFS_GATEWAYS[@]}; do
#        #this function should be more complex
#        if curl -s -m 30 https://$site/$IPFS_DIR/hashes.txt -o /tmp/dcomms; then
#            if (( $(stat -c %s /tmp/dcomms) > 3 )); then
#                IPFS_URL=https://$site/$IPFS_DIR/
#                printf "${GREEN}## Successfully connected to $site${NC}\n"
#                IPFS_REACHABLE=true
#                rm /tmp/dcomms
#                break
#            fi
#            rm /tmp/dcomms
#        fi
#    done
#
#    if [[ "${IPFS_REACHABLE}" == false ]]; then
#        printf "${RED}## Unable to connect to IPFS gateway${NC}\n"
#        ((i=i+=1))
#    fi

    # 'i' is the number of failed methods. Change as needed
    if (( i == 3 )); then
        printf "\n\n${RED}## All methods of retrieving Dcomms docker images have failed\n"
        printf "## Don't despair!\n"
        printf "## If you manage to retrieve the images listed below, place them in $DCOMMS_DIR \n"
	printf "## and re-run this script.\n"
        for i in ${D_IMAGES[@]}; do
             printf "$i\n"
        done
	printf "${NC}"
        exit 1
    fi

}

#Spins up a temporary docker container to generate synapse config files and keys
matrix_config () {
    printf "${YELLOW}## Generating synapse config${NC}\n"
    sudo docker run -it --rm \
        --mount type=bind,src=$(readlink -f $DCOMMS_DIR/conf/synapse),dst=/data \
        -e SYNAPSE_SERVER_NAME=matrix.$DWEB_DOMAIN \
        -e SYNAPSE_REPORT_STATS=no \
        -e SYNAPSE_DATA_DIR=/data \
    matrixdotorg/synapse:v1.53.0 generate >/dev/null
    sudo chown -R $USER:$USER $DCOMMS_DIR/conf/synapse/
    sed -i 's/#enable_registration: false/enable_registration: true/' $DCOMMS_DIR/conf/synapse/homeserver.yaml
    sed -i 's/#registration_requires_token: true/registration_requires_token: true/' $DCOMMS_DIR/conf/synapse/homeserver.yaml
    sed -i 's/#encryption_enabled_by_default_for_room_type: invite/encryption_enabled_by_default_for_room_type: all/' $DCOMMS_DIR/conf/synapse/homeserver.yaml
    sed -i 's/#rc_registration:/rc_registration:\n  per_second: 0.1 \n  burst_count: 2/' $DCOMMS_DIR/conf/synapse/homeserver.yaml
    sed -i 's/^presence:/presence:\n  enabled: false/' $DCOMMS_DIR/conf/synapse/homeserver.yaml
    sed -i "s/TEMPLATE/$DWEB_DOMAIN/" $DCOMMS_DIR/conf/element/config.json
}

#Mastodon's config file requires a number of keys to be generated. We spin up a temporary container to do this.
#Volume must be removed before running
mastodon_config () {
    sudo docker volume rm masto_data_tmp > /dev/null
    printf "${YELLOW}## Generating mastodon config${NC}\n"
    sudo cp -a $DCOMMS_DIR/conf/mastodon/example.env.production $DCOMMS_DIR/conf/mastodon/env.production
    SECRET_KEY_BASE=`sudo docker run -it --rm \
        --mount type=volume,src=masto_data_tmp,dst=/opt/mastodon \
            -e RUBYOPT=-W0 aphick/mastodon-sendmail:0.2 \
        bundle exec rake secret` >/dev/null

    OTP_SECRET=$(sudo docker run -it --rm \
        --mount type=volume,src=masto_data_tmp,dst=/opt/mastodon \
            -e RUBYOPT=-W0 aphick/mastodon-sendmail:0.2 \
        bundle exec rake secret) >/dev/null

    VAPID_KEYS=$(sudo docker run -it --rm \
        --mount type=volume,src=masto_data_tmp,dst=/opt/mastodon \
            -e RUBYOPT=-W0 aphick/mastodon-sendmail:0.2 \
        bundle exec rake mastodon:webpush:generate_vapid_key)>/dev/null
    VAPID_FRIENDLY_KEYS=${VAPID_KEYS//$'\n'/\\$'\n'}

    REDIS_PW=$(openssl rand -base64 12)

    sed -i "s/REPLACEME/$DWEB_DOMAIN/" $DCOMMS_DIR/conf/mastodon/env.production
    sed -i "s/SECRET_KEY_BASE=/&$SECRET_KEY_BASE/" $DCOMMS_DIR/conf/mastodon/env.production
    sed -i "s/OTP_SECRET=/&$OTP_SECRET/" $DCOMMS_DIR/conf/mastodon/env.production
    sed -i "s/VAPID_KEYS=/$VAPID_FRIENDLY_KEYS/" $DCOMMS_DIR/conf/mastodon/env.production
    sed -i 's/\r$//g' $DCOMMS_DIR/conf/mastodon/env.production
    sed -i "s/ALTERNATE_DOMAINS=mastodon./&$DWEB_ONION/" $DCOMMS_DIR/conf/mastodon/env.production
    sed -i "s/SMTP_SERVER=/&$DWEB_DOMAIN/" $DCOMMS_DIR/conf/mastodon/env.production
    #sed -i "s/REDIS_PASSWORD=/&$REDIS_PW/" $DCOMMS_DIR/conf/mastodon/env.production
}

mau_config () {
    printf "${YELLOW}## Generating mau bot config${NC}\n"
    sudo docker run --rm --mount type=bind,src=$(readlink -f $DCOMMS_DIR/conf/mau),dst=/data dock.mau.dev/maubot/maubot:v0.3.1 1>&2  >/dev/null
    sudo chown -R $USER:$USER $DCOMMS_DIR/conf/mau 
    MAU_PW=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 18)
    printf "${RED}## Mau credentials = admin:$MAU_PW${NC}\n"
    MAU_CREDS="admin:$MAU_PW"
    sed -i "s/admins:/&\n  admin: $MAU_PW/" $DCOMMS_DIR/conf/mau/config.yaml
}

#Use one of a number of means to grab docker images. 
#There NEEDS to be some kind of verification step in here that requires manual intervention
#Also ideally expand out the number of methods
grab_img () {
    if [[ "${LOCAL_FILES}" == true ]]; then
        for file in ${DOCKER_FILES[@]}; do
            if [ -f $DCOMMS_DIR/$file ]; then
                printf "${GREEN}$file found on disk. Adding to docker.${NC}\n"
                DOCKER_FILES=( "${DOCKER_FILES[@]/$file}" )
                cat $DCOMMS_DIR/$file | sudo docker load
            fi
        done
    fi
    if [[ "${HUB_REACHABLE}" == true ]]; then
        printf "${GREEN}### Grabbing images from Docker Hub.${NC}\n"
        for img in ${D_IMAGES[@]}; do
            sudo docker pull $img >/dev/null
        done
        return
    fi
    j=0
    printf "${YELLOW}### Unable to reach Docker Hub. Using mirror.${NC}\n"
    for file in ${DOCKER_FILES[@]}; do
        if [[ "${DCOMM_REACHABLE}" == true ]]; then
            curl $DCOMM_URL/$file -o $TMP_DIR_F/$file 
        elif [[ "${TORRENT_AVAIL}" == true ]]; then
            aria2c -d $TMP_DIR_F/$file --seed-time=0 "${FILE_MAGNETS[@]}" >/dev/null
        elif [[ "${IPFS_REACHABLE}" == true ]]; then
            curl $IPFS_URL/$file -o $TMP_DIR_F/$file
        fi
        ((j=j+=1))
    done
    #Might be wise to bring this out of this function so that we can validate before loading
    for f in $TMP_DIR_F/*.tar; do
        echo ""
        cat $f | sudo docker load
    done
}

#Grab config files from one of the available sources.
#Should also run validation
grab_cfg () {
    if [ -z $DCOMMS_DIR/$CONF_FILE ]; then
        tar -xvf $DCOMMS_DIR/$CONF_FILE -C $DCOMMS_DIR >/dev/null
    else
         if [[ "${DCOMM_REACHABLE}" == true ]]; then
            printf "${GREEN}### Grabbing config from Dcomms.${NC}\n"
            curl $DCOMM_URL/$CONF_FILE -o $TMP_DIR_C/$CONF_FILE
        elif [[ "${TORRENT_AVAIL}" == true ]]; then
            printf "${GREEN}### Grabbing config as a Torrent.${NC}\n"
            aria2c -d  $TMP_DIR_C/$CONF_FILE --seed-time=0 "$CONF_MAGNET"
        elif [[ "${IPFS_REACHABLE}" == true ]]; then
            printf "${GREEN}### Grabbing config from IPFS.${NC}\n"
            curl $IPFS_URL/$CONF_FILE -o $TMP_DIR_C/$CONF_FILE
        fi
        tar -xvf $TMP_DIR_C/$CONF_FILE -C $DCOMMS_DIR >/dev/null
    fi
}

#The main function does most of the configuration
main() {
    if [ -z $DCOMMS_DIR ]; then
        printf "${RED}No directory set for dcomms files.\nPlease edit the "
        printf "'DCOMMS_DIR' variable at the top of this script and run again.${NC}\n"
        exit 1
    elif [ -f $DCOMMS_DIR/run.sh ]; then
        printf "${RED}A previous installation of dcomms was found on this system.\n"
        printf "To start your services please use 'run.sh' in '$DCOMMS_DIR'.${NC}\n"
        exit 1
    elif [ -f $DCOMMS_DIR/caddy_2.5.1.tar ]; then
        #Should document how this works better. Offering sneakernet compatability is great.
        printf "${GREEN}Some dcomms Docker image files were found in $DCOMMS_DIR.\n"
        printf "Will use instead of downloading.${NC}\n"
        export LOCAL_FILES=true
    fi

    export NEWT_COLORS='
    root=,black
    checkbox=,black
    entry=,black
    '
    export DELTA=false
    export MATRIX=false
    export CENO=false
    export MAU=false
    export MASTO=false
    check_requirements

    DWEB_DOMAIN=$(whiptail --inputbox "What domain would you like to use?" 8 39 --title "Domain Name" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 1 ]; then
        printf "${RED}Exiting${NC}\n"
        exit 1
    elif [[ -z "${DWEB_DOMAIN}" ]]; then
        printf "${RED}This script requires a domain name to function.\n"
        printf "${RED}Exiting${NC}\n"
        exit 1
    fi

    export DWEB_DOMAIN=$DWEB_DOMAIN
    # Replace dots with dashes
    export DWEB_FRIENDLY_DOMAIN="${DWEB_DOMAIN//./_}"

    CHOICES=$(whiptail --separate-output --checklist "Which services would you like?" 10 35 5 \
      "1" "Delta Chat" ON \
      "2" "Element & Synapse" ON \
      "3" "Ceno Bridge" ON \
      "4" "Maubot" OFF \
      "5" "Mastodon" OFF 3>&1 1>&2 2>&3)

    if [ -z "$CHOICES" ]; then
      echo "No option was selected (user hit Cancel or unselected all options)"
      exit
    else
      for CHOICE in $CHOICES; do
        case "$CHOICE" in
        "1")
            D_IMAGES+=("keith/deltachat-mailadm-postfix:v0.0.3" "keith/deltachat-mailadm-dovecot:v0.0.1" "keith/deltachat-mailadm:v0.0.1")
            DOCKER_FILES+=("dovecot_v0.0.1.tar" "mailadm_v0.0.1.tar" "postfix_v0.0.3.tar")
            FILE_MAGNETS+=("${MAGNET_LINKS[2]}$MAG_TRACKERS" "${MAGNET_LINKS[4]}$MAG_TRACKERS" "${MAGNET_LINKS[3]}$MAG_TRACKERS")
            COMPOSE_FILES+="-f ./conf/compose/delta.docker-compose.yml "
            DELTA=true
          ;;
        "2")
            D_IMAGES+=("vectorim/element-web:v1.10.14" "matrixdotorg/synapse:v1.60.0")
            DOCKER_FILES+=("synapse_v1.60.0.tar" "element-web_v1.10.14.tar")
            FILE_MAGNETS+=("${MAGNET_LINKS[10]}$MAG_TRACKERS" "${MAGNET_LINKS[5]}$MAG_TRACKERS")
            COMPOSE_FILES+="-f ./conf/compose/element.docker-compose.yml "
            MATRIX=true
          ;;
        "3")
            D_IMAGES+=("equalitie/ceno-client:v0.21.1")
            DOCKER_FILES+=("ceno-client_v0.21.1.tar")
            FILE_MAGNETS+=("${MAGNET_LINKS[1]}$MAG_TRACKERS")
            COMPOSE_FILES+="-f ./conf/compose/bridge.docker-compose.yml "
            CENO=true
          ;;
        "4")
            D_IMAGES+=("dock.mau.dev/maubot/maubot:v0.3.1")
            DOCKER_FILES+=("maubot_v0.3.1.tar")
            FILE_MAGNETS+=("${MAGNET_LINKS[7]}$MAG_TRACKERS")
            COMPOSE_FILES+="-f ./conf/compose/mau.docker-compose.yml "
            MAU=true
          ;;
        "5")
            D_IMAGES+=("aphick/mastodon-sendmail:0.2" "redis:6.0-alpine" "postgres:12.2-alpine")
            DOCKER_FILES+=("mastodon-sendmail_0.2.tar" "postgres_12.2.tar" "redis_6.0.tar")
            FILE_MAGNETS+=("${MAGNET_LINKS[6]}$MAG_TRACKERS" "${MAGNET_LINKS[8]}$MAG_TRACKERS" "${MAGNET_LINKS[9]}$MAG_TRACKERS")
            COMPOSE_FILES+="-f ./conf/compose/mastodon.docker-compose.yml "
            MASTO=true
          ;;
        *)
          echo "Unsupported item $CHOICE!" >&2
          exit 1
          ;;
        esac
      done
    fi

    TMP_DIR_F=$(mktemp -d)    
    TMP_DIR_C=$(mktemp -d)

    trap 'rm -rf "$TMP_DIR_C" && rm -rf "$TMP_DIR_F"' EXIT 

    if [[ "${MAU}" == true ]] && [[ "${MATRIX}" == false ]]; then
        print "${RED}##Mau is a Matrix bot. You must install Matrix as well.${NC}\n"
        exit
    fi

    if [[ "${TOR_AVAIL}" == true ]]; then
        DWEB_ONION=$(whiptail --inputbox "Add a hidden service address (Optional)" 8 44 --title "HS Address" 3>&1 1>&2 2>&3)
        export DWEB_ONION=$DWEB_ONION
    fi

    detect_connectivity

    if [[ "${LOCAL_FILES}" == false ]]; then
        mkdir $DCOMMS_DIR
    fi
    grab_img
    grab_cfg


    if [[ "${MATRIX}" == true ]]; then
        matrix_config
    fi
    if [[ "${MAU}" == true ]]; then
        mau_config
    fi
    if [[ "${MASTO}" == true ]]; then
        mastodon_config
    fi
    echo "#!/bin/bash" > $DCOMMS_DIR/run.sh
    echo 'echo "Mau credentials = '${MAU_CREDS}'"' >> $DCOMMS_DIR/run.sh
    echo "sudo DWEB_ONION=$DWEB_ONION DWEB_DOMAIN=$DWEB_DOMAIN DWEB_FRIENDLY_DOMAIN=$DWEB_FRIENDLY_DOMAIN docker compose $COMPOSE_FILES up -d" >> $DCOMMS_DIR/run.sh
    chmod +x $DCOMMS_DIR/run.sh
    printf "${GREEN} Dcomms succesfully installed! Start your services by running 'run.sh' in $DCOMMS_DIR.${NC}\n"
}

main

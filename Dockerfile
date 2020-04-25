#!/usr/bin/env -S docker build --compress -t wrenchpilot/tableau:2020.1.2:build -f

FROM centos/systemd

WORKDIR /data

ARG version=2020.1.2

ENV pkg_tabcmd https://downloads.tableau.com/esdalt/\${version}/tableau-tabcmd-\${version//./-}.noarch.rpm
ENV pkg_server https://downloads.tableau.com/esdalt/\${version}/tableau-server-\${version//./-}.x86_64.rpm

RUN eval curl -#Lo ./tableau-tabcmd.rpm "${pkg_tabcmd}"
RUN eval curl -#Lo ./tableau-server.rpm "${pkg_server}"

# hack
RUN mkdir -p /run/systemd/system

RUN touch /usr/local/bin/sysctl \
    && chmod +x /usr/local/bin/sysctl

RUN echo 'seq 0 9 | xargs -I% -- echo %,%' \
    | tee /usr/local/bin/lscpu \
    && chmod +x /usr/local/bin/lscpu
RUN echo cpu: $(lscpu -p | grep -E -v '^#' | sort -u -t, -k 2,4 | wc -l)

RUN echo 'echo; echo mem: 32768' \
    | tee /usr/local/bin/free \
    && chmod +x /usr/local/bin/free
RUN echo mem: $(free -m | awk 'NR == 2 { print $2; }')

RUN yum install -y iputils iproute sudo
RUN yum install -y \
    ./tableau-tabcmd.rpm \
    ./tableau-server.rpm \
    || rpm -i \
    --nodigest \
    --noscripts \
    --notriggers \
    --nosignature \
    --nofiledigest \
    ./tableau-server.rpm \
    || echo something fucked up

RUN ln -svf /opt/tableau/tabcmd/bin/tabcmd \
    /usr/local/bin
RUN ln -svf /opt/tableau/tableau_server/packages/scripts.*/initialize-tsm \
    /usr/local/bin
RUN find /opt/tableau/tableau_server/packages/customer-bin.* \
    -not -type d -exec ln -svf {} /usr/local/bin/ \;

ARG USER=tableau
RUN ( \
       	echo "${USER} ALL=(ALL) NOPASSWD:ALL" ; \
        echo "Defaults:${USER} !requiretty"   ; \
        echo "Defaults secure_path = $PATH"   ; \
    ) | tee -a /etc/sudoers.d/sudo
RUN useradd -g users -m "${USER}"

RUN ( \
       	echo "runuser -l ${USER} -c 'sudo $(realpath $(which initialize-tsm)) --accepteula'"; \
    ) | tee -a /etc/rc.local

RUN echo "${USER}:${USER}" | chpasswd
RUN systemctl enable rc-local || chmod +x /etc/rc.d/rc.local

EXPOSE 80 443 8316 8381 8731 8749 8780 8850

# example: 

#sudo docker run --rm --privileged -it -p8850:8850 -p80:80 \
#-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#-v /opt/tableau/tableau_driver:/opt/tableau/tableau_driver \
#wrenchpilot/tableau

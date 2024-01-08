FROM ubuntu:18.04 as base-stage

ENV WORK_DIR /opt/application
ENV EOSIO_PACKAGE_URL https://github.com/siliconswampio/wire-eosio/releases/download/v2.0.13/eosio_2.0.13-1_amd64.deb
ENV EOSIO_CDT_OLD_URL https://github.com/eosio/eosio.cdt/releases/download/v1.6.3/eosio.cdt_1.6.3-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_URL https://github.com/siliconswampio/wire-eosio-cdt/releases/download/v1.7.0/eosio.cdt_1.7.0-1_amd64.deb

RUN apt-get update && apt-get install -y wget jq git build-essential cmake

RUN wget -O /eosio.deb $EOSIO_PACKAGE_URL \
  && wget -O /eosio-cdt-v1.7.0.deb $EOSIO_CDT_URL \
  && wget -O /eosio-cdt-v1.6.3.deb $EOSIO_CDT_OLD_URL

RUN apt-get install -y /eosio.deb

RUN apt-get install -y /eosio-cdt-v1.6.3.deb \
  && git clone https://github.com/EOSIO/eosio.contracts.git /opt/old-eosio.contracts \
  && cd /opt/old-eosio.contracts && git checkout release/1.8.x \
  && rm -fr build \
  && mkdir build  \
  && cd build \
  && cmake .. \
  && make -j$(sysctl -n hw.ncpu)

RUN apt-get install -y /eosio-cdt-v1.7.0.deb \
  && git clone https://github.com/siliconswampio/wire-eosio-contracts.git /opt/eosio.contracts \
  && cd /opt/eosio.contracts && git checkout tags/v1.0.4 \
  && rm -fr build \
  && mkdir build  \
  && cd build \
  && cmake .. \
  && make -j$(sysctl -n hw.ncpu)

# Remove all of the unnecessary files and apt cache
RUN rm -Rf /eosio*.deb \
  && apt-get remove -y wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Define working directory
WORKDIR $WORK_DIR

# ------------------------------

FROM base-stage as prod-stage

ENV WORK_DIR /opt/application
# Define Environment params used by start.sh
ENV DATA_DIR /root/data-dir
ENV CONFIG_DIR $DATA_DIR/config
ENV BACKUPS_DIR /root/backups

# RUN chmod +x $WORK_DIR/start.sh

CMD ["/opt/application/start.sh"]

# ------------------------------

FROM base-stage as local-stage

ENV WORK_DIR /opt/application

RUN apt-get update && apt-get install -y --no-install-recommends jq curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Define Environment params used by start.sh
ENV DATA_DIR /root/data-dir
ENV CONFIG_DIR $DATA_DIR/config
ENV BACKUPS_DIR /root/backups

RUN mkdir -p $DATA_DIR

# RUN chmod +x $WORK_DIR/start.sh

CMD ["/opt/application/start.sh"]

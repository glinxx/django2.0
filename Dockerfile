FROM ubuntu:artful
COPY nginx_signing.key /tmp/nginx_signing.key	
RUN apt-key add /tmp/nginx_signing.key	
RUN echo "deb http://nginx.org/packages/ubuntu/ artful nginx" >> /etc/apt/sources.list
ENV TZ 'Asia/Hong_Kong'
RUN echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install -y python3-dev python3-pip ca-certificates nginx libffi-dev libssl-dev freetds-dev libjpeg-dev libfreetype6-dev unzip libaio1 vim tzdata && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

COPY oracle-libs/instantclient* /tmp/
RUN unzip "/tmp/instantclient*.zip" -d /opt/oracle  && \
    mkdir /opt/oracle/instantclient_11_2/network/admin -p  && \
    ln -s /opt/oracle/instantclient_11_2/libclntsh.so.11.1 /opt/oracle/instantclient_11_2/libclntsh.so  && \
    echo "/opt/oracle/instantclient_11_2/" > /etc/ld.so.conf.d/oracle.conf  && \
    ldconfig -v

ENV ORACLE_BASE=/opt/oracle
ENV ORACLE_HOME=$ORACLE_BASE/instantclient_11_2
ENV PATH=$ORACLE_HOME:$PATH
ENV LD_LIBRARY_PATH=$ORACLE_HOME:$ORACLE_HOME/sdk:${LD_LIBRARY_PATH}
ENV TNS_ADMIN=$ORACLE_HOME/network/admin
ENV NLS_LANG=AMERICAN_AMERICA.UTF8

ENV workspace /autolife

VOLUME ${workspace}
WORKDIR ${workspace}

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

COPY nginx.conf /tmp/default.conf
COPY 1_wx.meidongauto.com_bundle.crt /tmp/1_wx.meidongauto.com_bundle.crt
COPY 2_wx.meidongauto.com.key /tmp/2_wx.meidongauto.com.key
RUN rm /etc/nginx/conf.d/default.conf  && \
    ln -s /tmp/default.conf /etc/nginx/conf.d/  && \
    ln -s /tmp/1_wx.meidongauto.com_bundle.crt /etc/nginx/  && \
    ln -s /tmp/2_wx.meidongauto.com.key /etc/nginx/  && \
    ln -sf /dev/stdout /var/log/nginx/access.log  && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

CMD uwsgi --ini uwsgi.ini && nginx -g 'daemon off;'

# Postgresql 9.5 (http://www.postgresql.org/)
# Based on https://github.com/Painted-Fox/docker-postgresql/

FROM phusion/baseimage:0.9.18
MAINTAINER Jonatan Heyman <http://heyman.info>

# Ensure we create the cluster with UTF-8 locale
RUN locale-gen en_US.UTF-8 && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale

# Add build scripts
ADD . /build

# Install the latest postgresql
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --force-yes \
        postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 postgresql-9.5-postgis-2.3 postgresql-9.5-postgis-scripts && \
    /etc/init.d/postgresql stop

# Install other tools.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pwgen inotify-tools

# Remove build scripts
RUN rm -rf /build

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# work around for AUFS bug
# as per https://github.com/docker/docker/issues/783#issuecomment-56013588
RUN mkdir /etc/ssl/private-copy; mv /etc/ssl/private/* /etc/ssl/private-copy/; rm -r /etc/ssl/private; mv /etc/ssl/private-copy /etc/ssl/private; chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private

# Cofigure the database to use our data dir.
RUN sed -i -e"s/data_directory =.*$/data_directory = '\/data'/" /etc/postgresql/9.5/main/postgresql.conf
# Allow connections from anywhere.
RUN sed -i -e"s/^#listen_addresses =.*$/listen_addresses = '*'/" /etc/postgresql/9.5/main/postgresql.conf
RUN echo "host    all    all    0.0.0.0/0    md5" >> /etc/postgresql/9.5/main/pg_hba.conf

EXPOSE 5432
ADD . /scripts
RUN chmod +x /scripts/start.sh
RUN touch /firstrun

# Add daemon to be run by runit.
RUN mkdir /etc/service/postgresql
RUN ln -s /scripts/start.sh /etc/service/postgresql/run

# Correct the Error: could not open temporary statistics file "/var/run/postgresql/9.5-main.pg_stat_tmp/global.tmp": No such file or directory
RUN mkdir -p /var/run/postgresql/9.5-main.pg_stat_tmp
RUN chown postgres:postgres /var/run/postgresql/9.5-main.pg_stat_tmp -R

# Expose our data, log, and configuration directories.
VOLUME ["/data", "/var/log/postgresql", "/etc/postgresql"]

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

ARG NEXUS_VERSION=3.40.1
FROM sonatype/nexus3:${NEXUS_VERSION}

USER root
RUN echo 'nexus.scripts.allowCreation=true' >> /opt/sonatype/nexus/etc/nexus-default.properties
RUN if [ ! -f /usr/bin/dnf ]; then ln -s /usr/bin/microdnf /usr/bin/dnf; fi
RUN dnf module -y reset ruby && dnf module -y enable ruby:2.7 && dnf install -y ruby && \
    dnf install -y redhat-rpm-config && dnf install -y ruby-devel make gcc gcc-c++ && \
    gem install bundler -v 2.1.4
RUN mkdir -p /user/gems /nexus3_rest && chown nexus: /user/gems /nexus3_rest

USER nexus
ENV BUNDLE_PATH=/user/gems
COPY Gemfile* /nexus3_rest
RUN cd /nexus3_rest && bundle

WORKDIR /nexus3_rest

CMD ["/nexus3_rest/docker/start.sh"]

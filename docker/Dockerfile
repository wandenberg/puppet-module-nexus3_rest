ARG NEXUS_VERSION=3.40.1
FROM sonatype/nexus3:${NEXUS_VERSION}

USER root
RUN echo 'nexus.scripts.allowCreation=true' >> /opt/sonatype/nexus/etc/nexus-default.properties
RUN dnf module -y reset ruby && dnf module -y enable ruby:2.7 && dnf module -y update ruby:2.7 && \
    dnf install -y redhat-rpm-config && yum install -y ruby-devel make gcc gcc-c++ && \
    gem install bundler
RUN mkdir -p /user/gems /nexus3_rest && chown nexus: /user/gems /nexus3_rest

USER nexus
ENV BUNDLE_PATH=/user/gems
COPY Gemfile* /nexus3_rest
RUN cd /nexus3_rest && bundle

WORKDIR /nexus3_rest

CMD ["/nexus3_rest/docker/start.sh"]

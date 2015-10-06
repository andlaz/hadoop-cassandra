FROM andlaz/hadoop-base
MAINTAINER andras.szerdahelyi@gmail.com

ENV CASSANDRA_CONFIG /etc/cassandra/conf

ADD etc/yum.repos.d/* /etc/yum.repos.d/

RUN yum -y install cassandra21-2.1.7 \
		cassandra21-tools-2.1.7 \
		ruby-2.0.0.598 \
		rubygems-2.0.14

RUN gem install thor

ADD etc/cassandra/conf/* /etc/cassandra/conf/
ADD etc/hadoop/* /etc/hadoop/
ADD etc/supervisor/conf.d/* /etc/supervisor/conf.d/
ADD etc/datastax-agent/* /etc/datastax-agent/

ADD http://downloads.datastax.com/community/datastax-agent-5.2.1.tar.gz /opt/
RUN cd /opt && tar xf datastax-agent-5.2.1.tar.gz && rm datastax-agent-5.2.1.tar.gz
RUN rm -f /opt/datastax-agent-5.2.1/conf && ln -s /etc/datastax-agent /opt/datastax-agent-5.2.1/conf

RUN rm -f /etc/security/limits.d/cassandra.conf

# System ports ( ssh )
EXPOSE 22

# Cassandra ports ( gossip; ; ; thrift; ; ; ; )
EXPOSE 7199 7000 7001 9160 9042 8012 61621

# DataNode ports ( data transfer; http; https; ipc; datastax agent )
EXPOSE 50010 50075 50475 50020 61621

# YARN NodeManager ports
EXPOSE 8040 8042

ADD configure.rb /root/
ADD entrypoint.sh /root/
ENTRYPOINT ["/root/entrypoint.sh"]

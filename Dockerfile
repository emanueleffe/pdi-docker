# based on: https://github.com/diethardsteiner/diethardsteiner.github.io/tree/master/sample-files/pdi/docker-pdi

FROM openjdk:8-jdk

MAINTAINER Emanuele Fiore

# Set required environment vars
ENV PDI_RELEASE=8.3 \
    PDI_VERSION=8.3.0.0-371 \
    CARTE_PORT=8181 \
    PENTAHO_JAVA_HOME=/usr/local/openjdk-8/ \
    PENTAHO_HOME=/home/pentaho

# Create user
RUN mkdir ${PENTAHO_HOME} && \
    groupadd -r pentaho && \
    useradd -s /bin/bash -d ${PENTAHO_HOME} -r -g pentaho pentaho && \
    chown pentaho:pentaho ${PENTAHO_HOME}

# Add files
RUN mkdir $PENTAHO_HOME/docker-entrypoint.d $PENTAHO_HOME/templates $PENTAHO_HOME/scripts

COPY carte-*.config.xml $PENTAHO_HOME/templates/

COPY docker-entrypoint.sh $PENTAHO_HOME/scripts/

# Copy etl folder
ADD etl $PENTAHO_HOME/etl

RUN chown -R pentaho:pentaho $PENTAHO_HOME

# Switch to the pentaho user
USER pentaho

# Download PDI
RUN /usr/bin/wget \
    --progress=dot:giga \
    http://downloads.sourceforge.net/project/pentaho/Pentaho%20${PDI_RELEASE}/client-tools/pdi-ce-${PDI_VERSION}.zip \
    -O /tmp/pdi-ce-${PDI_VERSION}.zip && \
    /usr/bin/unzip -q /tmp/pdi-ce-${PDI_VERSION}.zip -d  $PENTAHO_HOME && \
    rm /tmp/pdi-ce-${PDI_VERSION}.zip

# We can only add KETTLE_HOME to the PATH variable now
# as the path gets eveluated - so it must already exist
ENV KETTLE_HOME=$PENTAHO_HOME/data-integration \
    PATH=$KETTLE_HOME:$PATH

# Add missing css and icons
COPY static.zip $KETTLE_HOME
# Add additional libraries to kettle lib folder
ADD lib $KETTLE_HOME/lib

USER root

RUN /usr/bin/unzip -q $KETTLE_HOME/static.zip -d $KETTLE_HOME && rm $KETTLE_HOME/static.zip -f
RUN rm $KETTLE_HOME/static.zip -f
RUN chown pentaho:pentaho -R $KETTLE_HOME/static && chown pentaho:pentaho -R $PENTAHO_HOME/etl && chown pentaho:pentaho -R $KETTLE_HOME/lib

USER pentaho

# Expose Carte Server
EXPOSE ${CARTE_PORT}

# As we cannot use env variable with the entrypoint and cmd instructions
# we set the working directory here to a convenient location
# We set it to KETTLE_HOME so we can start carte easily
WORKDIR $KETTLE_HOME

RUN ["chmod", "+x", "../scripts/docker-entrypoint.sh"]

ENTRYPOINT ["../scripts/docker-entrypoint.sh"]

# Run Carte - these parameters are passed to the entrypoint
CMD ["carte.sh", "carte.config.xml"]

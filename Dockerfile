FROM mediawiki

# Install updates
RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y && \
    # Mail dependencies
    pear install mail net_smtp && \
    # Parsoid support
    apt-get install -y apt-transport-https && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y nodejs && \
    echo "deb http://releases.wikimedia.org/debian jessie-mediawiki main" | tee /etc/apt/sources.list.d/parsoid.list && \
    apt-key advanced --keyserver keys.gnupg.net --recv-keys 90E9F83F22250DD7 && \
    apt-get update && apt-get install -y parsoid && \
    apt-get autoremove -y  && apt-get clean && rm -r /var/lib/apt/lists/*

ENV APP_DIR=/var/www/html
ENV EXTENSIONS="Duplicator Echo MobileFrontend VisualEditor"

WORKDIR $APP_DIR/data

# Install extensions
RUN cd $APP_DIR/extensions && \
    for EXTENSION in $EXTENSIONS; do \
        cd $APP_DIR/extensions && \
        git clone --depth 1 -b $MEDIAWIKI_BRANCH https://gerrit.wikimedia.org/r/p/mediawiki/extensions/"$EXTENSION".git && \
        cd $APP_DIR/extensions/$EXTENSION && \
        git submodule update --init ; \
    done && \
    chown -R 1000.1000 $APP_DIR/extensions/

# Move all persistent data to $APP_DIR/data
# and fallback compatibility with symbolic links
RUN mkdir -p $APP_DIR/data && \
    # Image dir
    mv $APP_DIR/images/ $APP_DIR/data/images && \
    ln -s $APP_DIR/data/images $APP_DIR/images && \
    # Main config file
    ln -s $APP_DIR/data/LocalSettings.php $APP_DIR/LocalSettings.php

# Enable Apache Modules
RUN a2enmod rewrite

# .htaccess to volume
WORKDIR $APP_DIR
RUN ln -s data/conf_htaccess .htaccess

# Parsoid config
ADD parsoid $APP_DIR/parsoid
EXPOSE 8142

# Entrypoint
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD [""]

VOLUME ["$APP_DIR/data"]
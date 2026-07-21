FROM ruby:2.7-slim
LABEL maintainer="massimo@it20.info"

################## BEGIN INSTALLATION ######################

# Set the working directory to /app
WORKDIR /app

COPY *.rb ./
COPY Gemfile Gemfile
COPY modules modules

ENV LANG=en_us.UTF-8
ENV LC_ALL=C.UTF-8
ENV RACK_ENV=production

RUN apt-get update && \
    apt-get install -y build-essential curl libpq-dev && \
    rm -rf /var/lib/apt/lists/*

RUN bundle install

# Set the working directory to /
WORKDIR /
ADD startup.sh startup.sh

##################### INSTALLATION END #####################

CMD ["./startup.sh"]



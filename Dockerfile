FROM ruby:2.5.3-alpine

RUN mkdir -p /app
WORKDIR /app

RUN apk add --no-cache git openssh-client \
                       gcc \
                       yaml-dev \
                       glib-dev libc-dev make g++ \
                       postgresql-dev postgresql-client \
                       libxslt-dev zlib-dev \
                       tzdata \
                       zip \
                       gnuplot
                       
ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

ARG SECRET_KEY_BASE=secret

COPY . /app

RUN bundle config --global froze 1 && \
    bundle config --global build.nokogiri --use-system-libraries && \ 
    bundle install


RUN bundle exec rake DATABASE_URL=postgresql:does_not_exist app:assets:precompile

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]

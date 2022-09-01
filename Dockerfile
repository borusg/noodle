# docker build -t noodle .
#
# Check if you leaked secrets:
# docker history my-fancy-image

FROM ruby:2.7.6-alpine3.16 AS BUILDER

RUN apk add --update build-base

# Application dependencies
#    bundle config set path /srv/vendor/bundle &&    \
COPY Gemfile Gemfile.lock ./
RUN echo 'gem: --no-document' >> ~/.gemrc &&        \
    bundle config set without 'development test' && \
    bundle install

# The final image: we start clean
FROM ruby:2.7.6-alpine3.16

RUN adduser -D noodle
USER noodle

# We copy over the entire gems directory for our builder image, containing the already built artifact
COPY --chown=noodle --from=builder /usr/local/bundle/ /usr/local/bundle/

# Source code
WORKDIR /srv
COPY --chown=noodle . .pw/docker ./

# Start! Listen on all IP addresses because Docker.
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]

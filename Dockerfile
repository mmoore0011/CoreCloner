FROM ruby:alpine

# add gems - note, since we're using alpine we need build tools
RUN apk add --no-cache build-base && \
    gem install rbvmomi trollop 

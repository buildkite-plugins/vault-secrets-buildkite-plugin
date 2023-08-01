FROM vault:1.13.3

# vault doesn't include bash by default, and we want some functionality that bash provides
# so we'll install it manually and pin the version
RUN apk add bash=5.2.15-r5

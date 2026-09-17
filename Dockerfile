FROM vault:1.13.3

# vault doesn't include bash by default, and we want some functionality that bash provides
# so we'll install it manually and pin the version
# Install openssh so that we can run sshkey intgeration tests
RUN apk add bash=5.3.9-r1 openssh=9.3_p2-r3

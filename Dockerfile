FROM hashicorp/vault:2.2.2

# vault doesn't include bash by default, and we want some functionality that bash provides
# so we'll install it manually and pin the version
# Install openssh so that we can run sshkey intgeration tests
RUN apk add --no-cache bash=5.3.3-r1 openssh=10.2_p1-r1

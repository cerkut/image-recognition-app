# FROM ubuntu:20.04
FROM edgeimpulse/transformation-block-ubuntu:20.04

# Install any dependencies here
# RUN apt update && apt install -y ...

# Copy the script into the container
COPY hello.sh /hello.sh

# Make sure the script is executable
RUN chmod +x /hello.sh

# The entrypoint for the transformation block
ENTRYPOINT ["/hello.sh"]

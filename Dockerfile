# Use the official OpenResty image as the base image (Ubuntu Jammy 22.04)
FROM openresty/openresty:jammy

# Install necessary packages and Lapis framework
RUN apt install -y libssl-dev git build-essential
RUN /usr/local/openresty/luajit/bin/luarocks install lapis
RUN /usr/local/openresty/luajit/bin/luarocks install moonscript
RUN /usr/local/openresty/luajit/bin/luarocks install pgmoon
RUN /usr/local/openresty/luajit/bin/luarocks install luasocket
RUN /usr/local/openresty/luajit/bin/luarocks install bcrypt
RUN /usr/local/openresty/luajit/bin/luarocks install busted

# Set up the application directory
RUN mkdir /app
WORKDIR /app

# Set environment variables for Lapis and OpenResty
ENV LAPIS_OPENRESTY="/usr/local/openresty/bin/openresty"

# Define volume for application code
VOLUME /app

# Expose ports for the Lapis application
EXPOSE 8080 80

# Set the entrypoint to the Lapis command-line tool
ENTRYPOINT ["/usr/local/openresty/luajit/bin/lapis"]

# Default command to start the Lapis server in development mode
CMD ["server", "development"]
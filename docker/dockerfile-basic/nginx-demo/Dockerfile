FROM nginx:stable-alpine
LABEL maintainer="krsy0411"

WORKDIR /usr/share/nginx/html

# Copy static site files
COPY ./html /usr/share/nginx/html

# Custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]

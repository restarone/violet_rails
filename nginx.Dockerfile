FROM nginx
RUN apt-get update -qq && apt-get -y install apache2-utils
ENV APP_PATH /var/app
WORKDIR $APP_PATH
RUN mkdir log
RUN touch log/nginx.access.log
RUN touch log/nginx.error.log
COPY public public/
COPY nginx.conf /tmp/docker.nginx
RUN envsubst '$APP_PATH' < /tmp/docker.nginx > /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD [ "nginx", "-g", "daemon off;" ]
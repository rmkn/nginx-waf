FROM rmkn/centos7
LABEL maintainer "rmkn"

ENV OPENSSL_VERSION 1.1.1d
ENV LUAJIT_VERSION 2.1-20190912
ENV NDK_VERSION 0.3.1
ENV LUAMOD_VERSION 0.10.15
ENV HEADERS_MORE_VERSION 0.33
ENV MODSECURITY_NGINX_VERSION 1.0.0
ENV RESTY_CORE_VERSION 0.1.17
ENV RESTY_LRUCACHE_VERSION 0.09
ENV NGINX_VERSION 1.16.1
ENV OWASP_CRS_VERSION 3.1.0
ENV LUAROCKS_VERSION 3.2.1

RUN yum -y install libtool autoconf git file make gcc-c++ flex bison yajl yajl-devel curl-devel curl GeoIP-devel doxygen pcre-devel zlib-devel ccache unzip

RUN curl -o /usr/local/src/openssl.tar.gz -SL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/openssl.tar.gz -C /usr/local/src \
	&& cd /usr/local/src/openssl-${OPENSSL_VERSION} \
	&& ./config no-threads shared zlib -g enable-ssl3 enable-ssl3-method --prefix=/usr/local/openssl -Wl,-rpath,/usr/local/openssl/lib \
	&& make CC='ccache gcc -fdiagnostics-color=always' \
	&& make install_sw

RUN curl -o /usr/local/src/luajit.tar.gz -SL https://github.com/openresty/luajit2/archive/v${LUAJIT_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/luajit.tar.gz -C /usr/local/src \
	&& cd /usr/local/src/luajit2-${LUAJIT_VERSION} \
	&& make PREFIX=/usr/local/luajit \
	&& make install PREFIX=/usr/local/luajit

RUN curl -o /usr/local/src/ndk.tar.gz -SL https://github.com/simpl/ngx_devel_kit/archive/v${NDK_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/ndk.tar.gz -C /usr/local/src

RUN curl -o /usr/local/src/lua-nginx.tar.gz -SL https://github.com/openresty/lua-nginx-module/archive/v${LUAMOD_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/lua-nginx.tar.gz -C /usr/local/src

RUN curl -o /usr/local/src/headers-more-nginx.tar.gz -SL https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/headers-more-nginx.tar.gz -C /usr/local/src

RUN cd /usr/local/src \
	&& git clone https://github.com/SpiderLabs/ModSecurity \
	&& cd /usr/local/src/ModSecurity \
	&& ./build.sh \
	&& git submodule init \
	&& git submodule update \
	&& ./configure  \
	&& make \
	&& make install

RUN curl -o /usr/local/src/modsecurity-nginx.tar.gz -SL https://github.com/SpiderLabs/ModSecurity-nginx/archive/v${MODSECURITY_NGINX_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/modsecurity-nginx.tar.gz -C /usr/local/src

RUN curl -o /usr/local/src/lua-resty-core.tar.gz -SL https://github.com/openresty/lua-resty-core/archive/v${RESTY_CORE_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/lua-resty-core.tar.gz -C /usr/local/src \
	&& cp -r /usr/local/src/lua-resty-core-${RESTY_CORE_VERSION}/lib /usr/local/lib/resty

RUN curl -o /usr/local/src/lua-resty-lrucache.tar.gz -SL https://github.com/openresty/lua-resty-lrucache/archive/v${RESTY_LRUCACHE_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/lua-resty-lrucache.tar.gz -C /usr/local/src \
	&& cp -r /usr/local/src/lua-resty-lrucache-${RESTY_LRUCACHE_VERSION}/lib/resty/* /usr/local/lib/resty/resty/

ENV LUAJIT_LIB /usr/local/luajit/lib
ENV LUAJIT_INC /usr/local/luajit/include/luajit-2.1

RUN curl -o /usr/local/src/nginx.tar.gz -SL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/nginx.tar.gz -C /usr/local/src
RUN cd /usr/local/src/nginx-${NGINX_VERSION} \
	&& ./configure \
		--prefix=/usr/local/nginx \
		--with-ld-opt="-Wl,-rpath,/usr/local/luajit/lib:/usr/local/openssl/lib -L/usr/local/openssl/lib" \
		--with-cc-opt="-I/usr/local/openssl/include" \
		--with-ipv6 \
		--with-http_ssl_module \
		--with-http_v2_module \
		--with-http_realip_module \
		--with-http_stub_status_module \
		--add-dynamic-module=../ngx_devel_kit-${NDK_VERSION} \
		--add-dynamic-module=../lua-nginx-module-${LUAMOD_VERSION} \
		--add-dynamic-module=../ModSecurity-nginx-${MODSECURITY_NGINX_VERSION} \
		--add-dynamic-module=../headers-more-nginx-module-${HEADERS_MORE_VERSION} \
	&& make \
	&& make install

RUN ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx

RUN curl -o /usr/local/src/owasp-modsecurity-crs.tar.gz -SL https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v${OWASP_CRS_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/owasp-modsecurity-crs.tar.gz -C /usr/local \
	&& cd /usr/local \
	&& ln -sf owasp-modsecurity-crs-${OWASP_CRS_VERSION} owasp-modsecurity-crs \
	&& mv /usr/local/owasp-modsecurity-crs/crs-setup.conf.example /usr/local/owasp-modsecurity-crs/crs-setup.conf

RUN curl -o /usr/local/src/luarocks.tar.gz -SL https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
	&& tar zxf /usr/local/src/luarocks.tar.gz  -C /usr/local/src \
	&& cd /usr/local/src/luarocks-${LUAROCKS_VERSION} \
	&& ./configure --with-lua=/usr/local/luajit/ \
	&& make \
	&& make install

COPY nginx.conf /usr/local/nginx/conf/
COPY security.conf virtual.conf /usr/local/nginx/conf/conf.d/
COPY main.conf /usr/local/nginx/modsec/
COPY openssl.cnf /usr/local/openssl/ssl/
RUN cp /usr/local/src/ModSecurity/modsecurity.conf-recommended /usr/local/nginx/modsec/modsecurity.conf 
RUN cp /usr/local/src/ModSecurity/unicode.mapping /usr/local/nginx/modsec/

EXPOSE 80 443

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]

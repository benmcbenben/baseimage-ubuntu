FROM ubuntu:18.04

ADD pre_install /

RUN	set -xe \
	echo '#!/bin/sh' > /usr/sbin/policy-rc.d && \
	echo 'exit 101' >> /usr/sbin/policy-rc.d && \
	chmod +x /usr/sbin/policy-rc.d && \
	dpkg-divert --local --rename --add /sbin/initctl && \
	cp -a /usr/sbin/policy-rc.d /sbin/initctl && \
	sed -i 's/^exit.*/exit 0/' /sbin/initctl && \
	export DEBIAN_FRONTEND=noninteractive && \
	export LC_ALL=C && \
	export INITRD=no && \
	dpkg-divert --local --rename --add /sbin/initctl && \
	ln -sf /bin/true /sbin/initctl && \
	dpkg-divert --local --rename --add /usr/bin/ischroot && \
	ln -sf /bin/true /usr/bin/ischroot && \
	\
	sed -i 's/^#\s*\(deb.*main restricted\)$/\1/g' /etc/apt/sources.list && \
	sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list && \
	sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list && \
	apt-get update && \
	apt-get -yq dist-upgrade && \
	apt-get -yq install --no-install-recommends \
		apt-transport-https \
		ca-certificates \
		dirmngr \
		gnupg \
		python3 \
                rsync \
		runit && \
	\
	mkdir -p /etc/my_init.d && \
	mkdir -p /etc/my_init.pre_shutdown.d && \
	mkdir -p /etc/my_init.post_shutdown.d && \
	mkdir /etc/container_environment && \
	chmod 700 /etc/container_environment && \
	echo -n no > /etc/container_environment/INITRD && \
	touch /etc/container_environment.sh && \
	touch /etc/container_environment.json && \
	groupadd -g 8377 docker_env && \
	chown :docker_env /etc/container_environment.sh /etc/container_environment.json && \
	chmod 640 /etc/container_environment.sh /etc/container_environment.json && \
	ln -s /etc/container_environment.sh /etc/profile.d/ && \
	\
	apt-get -yq install --no-install-recommends cron && \
	chmod 600 /etc/crontab && \
	rm -f /etc/cron.daily/standard && \
	rm -f /etc/cron.daily/upstart && \
	rm -f /etc/cron.daily/dpkg && \
	rm -f /etc/cron.daily/password && \
	rm -f /etc/cron.weekly/fstrim && \
	\
	apt-get -yq -o Dpkg::Options::="--force-confold" install --no-install-recommends syslog-ng-core && \
	mkdir -p /var/lib/syslog-ng && \
	touch /var/log/syslog && \
	chmod u=rw,g=r,o= /var/log/syslog && \
	\
	apt-get -yq install --no-install-recommends logrotate && \
	\
	apt-get -yq autoremove --purge && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* && \
	rm -f /var/log/dpkg.log /var/log/alternatives.log /var/log/bootstrap.log && \
	rm -f /var/log/apt/history.log /var/log/apt/term.log && \
	rm -rf /usr/share/groff/* /usr/share/info/* && \
	rm -rf /usr/share/lintian/* /usr/share/linda/* && \
	find /usr/share/man -type f -delete && \
	find /usr/share/doc -not -type d -not -name 'copyright' -delete && \
	find /usr/share/doc -type d -empty -delete

# We cannot simply add this directly, as it has symlinks that cause buildx to error out.
# ADD post_install /
COPY post_install/ /post_install

RUN cp -r /post_install/etc/service/* /etc/service/ && rm -rf /post_install/etc/service && cp -r /post_install/* / && rm -rf /post_install

CMD ["/sbin/my_init"]

FROM debian:stable

# Build base image Javascript&Python <3
USER root
WORKDIR /root
RUN apt -y update
RUN apt install -y curl
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -
RUN apt -y update
RUN apt -y upgrade
RUN apt-get -y install wget python3.9 python3.9-venv python3-pip nodejs git
RUN apt install -y unzip
RUN apt install -y  ca-certificates fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 lsb-release wget xdg-utils xvfb

# Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt install ./google-chrome-stable_current_amd64.deb -y
RUN wget https://chromedriver.storage.googleapis.com/112.0.5615.49/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip
RUN mv chromedriver /usr/local/bin
# firefox-esr
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.30.0/geckodriver-v0.30.0-linux64.tar.gz
RUN tar xzfv geckodriver-v0.30.0-linux64.tar.gz
RUN chmod +x ./geckodriver
RUN mv geckodriver /usr/local/bin

# Oracle client install
RUN apt install -y libaio1 unixodbc unixodbc-dev
RUN mkdir /opt/oracle
RUN cd /opt/oracle && wget https://download.oracle.com/otn_software/linux/instantclient/215000/instantclient-basic-linux.x64-21.5.0.0.0dbru.zip
RUN cd /opt/oracle && unzip instantclient-basic-linux.x64-21.5.0.0.0dbru.zip
RUN sh -c "echo /opt/oracle/instantclient_21_5 > /etc/ld.so.conf.d/oracle-instantclient.conf"
RUN ldconfig


# Add user tester to properly run browser with chromedriver
ARG USER_ID
ENV USER_ID=$USER_ID
RUN useradd -l -m -d /home/tester -u $USER_ID -g root -s /bin/bash tester
RUN chmod 777 -R /home/tester
RUN chown tester -R /home/tester

# Create virtual environment for user tester
# We are trying to be POSIX Oracle/Postgres/Mssql
USER tester
WORKDIR /home/tester
RUN python3.9 -m venv env
RUN /home/tester/env/bin/pip install selenium jupyterlab cx-oracle pyjwt[crypto] sqlalchemy pandas xlwt openpyxl flask pyodbc pymssql oracledb psycopg2-binary sqlacodegen ldap3 openai
RUN . env/bin/activate && npm install puppeteer --save
RUN . env/bin/activate && npm install ijavascript --save
RUN . env/bin/activate && ./node_modules/.bin/ijsinstall --spec-path=full
ADD puppeteer.ipynb /home/tester/
ADD python_selenium.ipynb /home/tester/
ENV DISPLAY :99
CMD ["/bin/sh", "-c", "/usr/bin/nohup /usr/bin/Xvfb :99 -screen 0 1920x1080x16 -nolisten tcp | /home/tester/env/bin/python -m jupyterlab --ip 0.0.0.0"]


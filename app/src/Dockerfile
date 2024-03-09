FROM public.ecr.aws/lambda/python:3.8

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}
COPY titanic_model.sav ${LAMBDA_TASK_ROOT}


# Hack to install chromium dependencies

RUN yum install -y -q sudo unzip

# Current stable version of Chromium

ENV CHROMIUM_VERSION=1002910

# Install Chromium

COPY install-browser.sh /tmp/

RUN /usr/bin/bash /tmp/install-browser.sh

FROM public.ecr.aws/lambda/python:3.9 as base

COPY chrome-deps.txt /tmp/

RUN yum install -y $(cat /tmp/chrome-deps.txt)

COPY --from=stage /opt/chrome /opt/chrome

COPY --from=stage /opt/chromedriver /opt/chromedriver

COPY create.py ${LAMBDA_TASK_ROOT}
COPY process.py ${LAMBDA_TASK_ROOT}

COPY requirements.txt ${LAMBDA_TASK_ROOT}

COPY db/ ${LAMBDA_TASK_ROOT}/db/

# Install the function's dependencies using file requirements.txt
# from your project folder.

COPY requirements.txt  .
RUN  pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "app.handler" ] 
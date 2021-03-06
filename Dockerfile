FROM alpine:3
ENV KUBE_VERSION v1.15.6

RUN apk add --no-cache --update bash jq

ADD https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

COPY main.sh /main.sh

ENTRYPOINT /main.sh

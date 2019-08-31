FROM golang:1.12.9-buster AS build

# avoid warning by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Or your actual UID, GID on Linux if not the default 1000
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Docker compose version
ARG COMPOSE_VERSION=1.24.0

# create a non-root user to use if preferred (https://aka.ms/vscode-remote/containers/non-root-user)
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME

# configure apt, install packages and tools
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # verify git, process tools, lsb-release installed
    && apt-get  -y install procps lsb-release

# [Optional] add sudo support
RUN apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# install Docker CE CLI
RUN apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common lsb-release \
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | (OUT=$(apt-key add - 2>&1) || echo $OUT) \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# install Docker Compose
RUN curl -sSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# install gocode-gomod (An autocompletion daemon for the Go programming language)
RUN go get -x -d github.com/stamblerre/gocode 2>&1 \
     && go build -o gocode-gomod github.com/stamblerre/gocode \
     && mv gocode-gomod $GOPATH/bin/

# install Go tools
RUN go get -u -v \
       github.com/mdempsky/gocode \
       github.com/uudashr/gopkgs/cmd/gopkgs \
       github.com/ramya-rao-a/go-outline \
       github.com/acroca/go-symbols \
       github.com/godoctor/godoctor \
       golang.org/x/tools/cmd/guru \
       golang.org/x/tools/cmd/gorename \
       github.com/rogpeppe/godef \
       github.com/zmb3/gogetdoc \
       github.com/haya14busa/goplay/cmd/goplay \
       github.com/sqs/goreturns \
       github.com/josharian/impl \
       github.com/davidrjenni/reftools/cmd/fillstruct \
       github.com/fatih/gomodifytags \
       github.com/cweill/gotests/... \
       golang.org/x/tools/cmd/goimports \
       golang.org/x/lint/golint \
       golang.org/x/tools/cmd/gopls \
       github.com/alecthomas/gometalinter \
       honnef.co/go/tools/... \
       github.com/golangci/golangci-lint/cmd/golangci-lint \
       github.com/mgechev/revive \
       github.com/cespare/reflex \
       github.com/oxequa/realize \
       github.com/derekparker/delve/cmd/dlv 2>&1

# clean-up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# install delve debugger
#RUN apk --update add --no-cache --virtual dependency git \
# && go get -u github.com/go-delve/delve/cmd/dlv \
# && go get -u github.com/cespare/reflex \
# && apk del dependency

#RUN mkdir /build
#ADD . /build/
#WORKDIR /build
#RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o hello .

#EXPOSE 2345

#FROM scratch
#COPY --from=build /build/hello /app/
#WORKDIR /app
#CMD [ "./hello" ]

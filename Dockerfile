FROM debian:bookworm-slim
ARG FLUTTER_VERSION=3.47.5
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | tar -xJ -C /opt && flutter config --no-analytics
WORKDIR /workspace
COPY pubspec.yaml analysis_options.yaml .metadata .fvmrc ./
COPY lib ./lib
COPY test ./test
RUN flutter pub get
CMD ["flutter", "test"]

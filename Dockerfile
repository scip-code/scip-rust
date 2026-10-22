FROM rust:1.89.0@sha256:e090f7b4adf86191313dba91260351d7f5e15cac0fe34f26706a805c0cb9641f

# eMudhra intermediate CA key compromise (https://emudhra.we-have-a-problem.com/):
# the base image ships ca-certificates 20230311+deb12u1, which still trusts the
# emSign ECC Root CA - G3 and Comodo AAA Certificate Services roots. curl, wget,
# git, Python and cargo (libcurl + OpenSSL) all read this system store.
# 20250419~deb12u2 removes them.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates=20250419~deb12u2 \
    && rm -rf /var/lib/apt/lists/*

# rustup (rustls via rustls-platform-verifier) downloads toolchains pinned by
# rust-toolchain files. 1.29.2 is the patched release (rustls-webpki 0.103.16).
RUN RUSTUP_VERSION=1.29.2 rustup self update \
    && rustup --version | grep -q '^rustup 1\.29\.2 '

COPY scip-rust /usr/local/bin/scip-rust

RUN chmod +x /usr/local/bin/scip-rust

RUN rustup component add rust-analyzer

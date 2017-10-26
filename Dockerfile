FROM ocaml/opam:ubuntu-17.04_ocaml-4.03.0

ADD . /typed_i18n

RUN sudo chown opam /typed_i18n
USER opam
WORKDIR /typed_i18n

VOLUME bin:/typed_i18n/bin

RUN make install && \
    make && \
    bin/typed_i18n.Linux --version

FROM ocaml/opam:ubuntu-17.04_ocaml-4.03.0

ADD . /typed_i18n

RUN sudo chown opam /typed_i18n
USER opam
WORKDIR /typed_i18n

RUN make install && \
    make

CMD bin/typed_i18n.Linux --version

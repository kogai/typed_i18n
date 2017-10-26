FROM ocaml/opam:ubuntu-17.04_ocaml-4.03.0

ADD . ~/typed_i18n
WORKDIR ~/typed_i18n

RUN make install

# RUN eval `opam config env` && \
#     sudo make
# RUN ls src

# RUN make bin/typed_i18n && \
#     bin/typed_i18n --version

# RUN bin/typed_i18n --version
